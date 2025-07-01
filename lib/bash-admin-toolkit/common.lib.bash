# common.lib.bash : Shared fonctions for install scripts

# Must be set before calling get_options, by the script which makes the call
unset options m_opt ;
declare -A options ;
declare -A m_opt ;

# Default variables - can be  change in the script which calling functions, between "source file" and call
HOSTS_FILE="/etc/hosts"
DEBUG=0

function install_service() {
    # $1 is service name
    if ! command -v $1 >/dev/null; then
	echo "[+] Installation de $1 ..."
	apt update
	apt install -y $1
    else
	echo "[i] $1 already installed..."
    fi
}

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
		    [ "${options["debug"]}" == "0" ] || echo "==> options[\"${m_opt[$index]}\"] = ${options[${m_opt[$index]}]}" ;
		fi
	    fi
	    index=$(echo $arg | sed -e 's/-//g') ;
	    [ "${options["debug"]}" != "3" ] || echo "$index // ${m_opt[$index]} // $arg" ;
	else
	    if [ -n "$index" ] ;then
		if [ -v m_opt["$index"] ] ;then
		    options[${m_opt[$index]}]=$arg ;
		    [ "${options["debug"]}" == "0" ] || echo "==> options[\"${m_opt[$index]}\"] = $arg" ;
		    [ "${options["debug"]}" != "3" ] || echo "$index // ${m_opt[$index]} // $arg" ;
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

# 🔧 Add iptables rule if doesn't exist
function add_iptables_rule() {
    local chain="$1"
    local rule="$2"
    echo "chain = $chain / rule = $rule"

    if iptables -C "$chain" $rule 2>/dev/null; then
        echo "[i] Règle déjà présente dans $chain : $rule"
    else
        echo 'iptables -A "$chain" $rule'
        echo "[+] Ajout règle iptables : $chain $rule"
    fi
}

# 💾 Persists iptables rules
function save_iptables() {
    echo "[*] Sauvegarde des règles iptables..."
    netfilter-persistent save
}

# 🟢 Starting service (SysVinit)
function start_service() {
    local svc="$1"
    echo "svc = $svc"

    echo "[*] Démarrage service $svc..."
    service "$svc" restart
    update-rc.d "$svc" defaults
}

function hosts_add() {
    # Example with following command to add "127.0.0.1 myweb myweb.mydomain" after line with "#nginx" in /etc/hosts
    # hosts_add myweb.mydomain "# nginx"
    FULL_NAME=$1
    HOST_NAME=${FULL_NAME/.*/}
    DOMAIN_NAME=${FULL_NAME/*./}
    if [ $DOMAIN_NAME == $HOST_NAME ] ;then
    DOMAIN_NAME="local"
    fi
    reference_line=$2

    hosts_line=0
    if grep -qi "$reference_line" $HOSTS_FILE ;then
        hosts_new_position=$(grep -i -n "$reference_line" $HOSTS_FILE)
        hosts_line=${hosts_new_position/:*/}
    fi
    if grep -qE "\s*$HOST_NAME[^\w-]*" $HOSTS_FILE ;then
        echo "[i] $HOST_NAME already exists in $HOSTS_FILE..."
    else
        echo "[+] Add $HOST_NAME in $HOSTS_FILE..."
        number_pattern='^[0-9]+$'
        if [[ "$hosts_line" =~ $number_pattern ]] && [ $hosts_line -gt 0 ] ;then
            eval "sed -i '${hosts_line}a 127.0.0.1\t$HOST_NAME $HOST_NAME.$DOMAIN_NAME' $HOSTS_FILE"
        else
            echo "127.0.0.1	$HOST_NAME $HOST_NAME.$DOMAIN_NAME" >> $HOSTS_FILE
        fi
    fi
}

function hosts_remove() {
    # Example with following command to remove "127.0.0.1 myweb myweb.mydomain" from /etc/hosts
    # hosts_remove myweb.mydomain
    # OR same result with :
    # hosts_remove myweb
    HOST_NAME=$1

    hosts_line=0
    if grep -qE "\s*$HOST_NAME[^\w-]*" $HOSTS_FILE ;then
        hosts_search=$(grep -n -E "\s*$HOST_NAME[^\w-]*" $HOSTS_FILE)
        hosts_line=${hosts_search/:*/}
        number_pattern='^[0-9]+$'
        if [[ "$hosts_line" =~ $number_pattern ]] && [ $hosts_line -gt 0 ] ;then
        echo "[-] Remove $HOST_NAME from $HOSTS_FILE..."
            eval "sed -i '${hosts_line}d' $HOSTS_FILE"
        fi
    else
        echo "[i] $HOST_NAME was not in $HOSTS_FILE..."
    fi
}

# 📝 Log simple
function log_step() {
    echo -e "\n===== $1 =====\n"
}

