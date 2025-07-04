# common.lib.bash : Shared fonctions for install scripts

# Must be set before calling get_options, by the script which makes the call
unset options m_opt env_variables
declare -A options
declare -A m_opt
declare -A env_variables
# Default variables - can be  change in the script which calling functions, between "source file" and call
HOSTS_FILE="/etc/hosts"
DEBUG=0

function get_options() {
    # Loop on each argument value - prefixed with - or -- it will consider as key, otherwise as a value
    index="";
    for arg in $@ ;do
	if [ $(expr index $arg -) = 1 ] ; then
	    if [ -n "$index" ] ;then
		valeur="1" ;
		if [ -n "$(echo $index | grep -e '^no')" ] ;then
		    valeur="0" ;
		    index=$(echo $index | sed -e 's/no//g') ;
		fi
		if [ -v m_opt["$index"] ] ;then
		    [ -z "${m_opt[$index]}" ] || options[${m_opt[$index]}]=$valeur ;
		fi
	    fi
	    index=$(echo $arg | sed -e 's/-//g') ;
	else
	    if [ -n "$index" ] ;then
		if [ -v m_opt["$index"] ] ;then
		    options[${m_opt[$index]}]=$arg ;
		fi
		index="" ;
	    fi
	fi
    done
    # Loop ended, the last argument is processed separatly
    if [ -n "$index" ] ;then
	valeur="1" ;
	if [ -n "$(echo $index | grep -e '^no')" ] ;then
	    valeur="0" ;
	    index=$(echo $index | sed -e 's/no//g') ;
	fi
	[ -v m_opt["$index"] ] && options[${m_opt[$index]}]=$valeur ;
    fi
}

# Set environment variables with default when not set for message and error handling
function fallback_env() {
    [ -n "$DEBUG_LEVEL" ] || DEBUG_LEVEL=0
    [ -n "$QUIET" ] || QUIET=1
    [ -n "$FORCE" ] || FORCE=0
    [ -n "$SAFE_INTERACTIVE" ] || SAFE_INTERACTIVE=0
    [ -n "$HELP" ] || HELP=0
}

# Set all !! unset !! environment variables from CLI options
function validate_env() {
	for idx in ${!env_variables[*]} ;do
		eval "[[ \"\$$idx\" != \"\" ]] || $idx=${options[${env_variables["$idx"]}]}"
	done
}

function debug_options() {
	local option_list="Option list"
	for idx in ${!options[*]} ;do
			option_list="$option_list\noptions[$idx] = ${options["$idx"]}"
	done
	log_debug 2 $option_list
}

function debug_env() {
	local option_list="Option list"
	for idx in ${!env_variables[*]} ;do
		eval "option_list=\"\$option_list\\n$idx = \$$idx\""
	done
	log_debug 2 $option_list
}

function install_service() {
    # $1 is service name
    if ! command -v $1 >/dev/null; then
		log_debug 2 "[+] Installation de $1 ..."
		apt update
		apt install -y $1
    else
		log_debug 2 "[i] $1 already installed..."
    fi
    log_debug 2 "[i] $1 is installed and ready."
}

# 🟢 Starting service (SysVinit)
function start_service() {
    local svc="$1"

    service "$svc" restart > /dev/null
    update-rc.d "$svc" defaults
    
}

# 🔧 Add iptables rule if doesn't exist
function add_iptables_rule() {
    local chain="$1"
    local rule="$2"

    if iptables -C "$chain" $rule 2>&1; then
        log_debug 2 "[i] Rule already set in $chain : $rule"
    else
        iptables -A "$chain" $rule 2>&1
    fi
}

# 💾 Persists iptables rules
function save_iptables() {
    safe_run_without_success "iptables persistence" netfilter-persistent save
}

function hosts_add() {
    # Example with following command to add "127.0.0.1 myweb myweb.mydomain" after line with "#nginx" in /etc/hosts
    # hosts_add myweb.mydomain "# nginx"
    FULL_NAME=$1
    shift
    reference_line=$*

    HOST_NAME=${FULL_NAME/.*/}
    DOMAIN_NAME=${FULL_NAME/*./}
    if [ $DOMAIN_NAME == $HOST_NAME ] ;then
		DOMAIN_NAME="local"
    fi

    position="\$"
    if grep -qi "$reference_line" $HOSTS_FILE ;then
        hosts_new_position=$(grep -i -n "$reference_line" $HOSTS_FILE)
        position=${hosts_new_position/:*/}
        log_debug 2 "HOST APPEND POSITION - Detected $reference_line in $HOSTS_FILE at position : $position"
    fi
    if [ -z "$(grep -qE '\s*$HOST_NAME\s+' $HOSTS_FILE)" ] ;then
		safe_run_without_success "addition of $HOSTNAME is in $HOSTS_FILE" eval "sed -i '${position}a 127.0.0.1\t$HOST_NAME $HOST_NAME.$DOMAIN_NAME' $HOSTS_FILE"
    fi
}

function hosts_remove() {
    # Example with following command to remove "127.0.0.1 myweb myweb.mydomain" from /etc/hosts
    # hosts_remove myweb.mydomain
    # OR same result with :
    # hosts_remove myweb
    HOST_NAME=$1

    hosts_line=0
    if grep -qE "\s*$HOST_NAME\s+" $HOSTS_FILE ;then
        hosts_search=$(grep -n -E "\s*$HOST_NAME\s+" $HOSTS_FILE)
        hosts_line=${hosts_search/:*/}
        log_debug 2 "HOST LINE REMOVAL - Detected line with \" $HOST_NAME \" in $HOSTS_FILE  at line : $hosts_line"
        number_pattern='^[0-9]+$'
        if [[ "$hosts_line" =~ $number_pattern ]] && [ $hosts_line -gt 0 ] ;then
            safe_run_without_success "$HOSTNAME removal from $HOSTS_FILE" eval "sed -i '${hosts_line}d' $HOSTS_FILE"
        fi
    else
        log_debug 2 "[i] $HOST_NAME was not in $HOSTS_FILE..."
    fi
}

function quiet_exec(){
    if [[ "${options['quiet']}" != "1" && "${options['debug']}" != "2" ]] ;then
		$@
    else
		# TODO : Log file instead of /dev/null
		$@ 2>/dev/null
    fi
}

function safe_run() {
    local desc="$1"
    shift
    
    (( ${options["debug"]} >= 1 )) && log_info " $desc is starting..."
    if quiet_exec "$@"; then
        log_success "Action(s) for $desc done successfuly."
    else
        log_failure $desc

        if [[ "${options['force']}" == "1" ]]; then
            [[ "$with_info" == "1" ]] && log_info "Failure in $desc. Continuing anyway (force mode enabled)"
            return 0
        fi

        log_debug 1 "Command failed: $*"

        if (( SAFE_INTERACTIVE == 1 )); then
            read -p "⚠️  Continue? (y/N): " choice
            [[ "$choice" =~ ^[Yy]$ ]] && return 0
        fi

        log_exit_on_failure
        exit 1
    fi
}

# Overload safe_run in order to block redundant log with variables without_success and without_info
function safe_run_without_success() {
    local desc_temp="$1"
    shift

	local without_success=1
	local without_info=1

	safe_run "$desc_temp" $*
}

# Overload safe_run in order to block redundant log with variables and without_info
function safe_run_without_info() {
    local desc_temp="$1"
    shift

	local without_info=1

	safe_run "$desc_temp" $*
}

function log_success() {
	# Introduce condition to modify safe_run comportment - this syntax in if is to avoid exit code not 0
	if [ -z "$(grep -E '^1$' <<< "$without_success")" -o $DEBUG_LEVEL -ge 2 ] ;then
		echo -e "${GREEN}[✔] OK${RESET}: $@"
    fi
}

function log_info() {
	# Introduce condition to modify safe_run comportment - this syntax in if is to avoid exit code not 0
	if [ -z "$(grep -E '^1$' <<< "$without_info")" -o $DEBUG_LEVEL -ge 2 ] ;then
		echo -e "${CYAN}[ℹ️] INFO${RESET}: $@"
	fi
}

function log_failure() {
    echo -e "${RED}[✘] Failed${RESET}: $@"
}

function log_exit_on_failure() {
    echo -e "${RED}[✘] Exiting due to error.${RESET} $@"
}

# Global debug level, 0 = off, 1 = info, 2 = verbose (to be defined with sourcing or environment variable): "${DEBUG_LEVEL:=0}"
function log_debug() {
    local level=$1
    shift
    if [ $DEBUG_LEVEL -ge $level ]; then
        echo -e "${PURPLE}[d] [DEBUG]${RESET} $*"
    fi
}

# Parse options["debug"] and overwrite DEBUG_LEVEL
# Should replace : [[ "$DEBUG_LEVEL" != "" ]] || DEBUG_LEVEL=${options["debug"]}
function set_debug_level() {
    if [[ "${options[debug]}" == "1" ]]; then
        DEBUG_LEVEL=1
    else
        DEBUG_LEVEL=0
    fi
}
