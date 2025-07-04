#!/bin/bash
#
# Filename       : bat-nginx-helper.sh
# Description    : after getting command line arguments, add or remove nginx site (config + test page + ssl certificate).
# Author         : Hervep530 - Copyright [2025]
# Date           : 2025-06-30
# Version        : 0.1.0
# License        : Apache 2.0
#
# Usage          : ./bat-nginx-helper.sh [options]
# Examples       : ./bat-nginx-helper.sh -v mynewsite -p 443   (set and start new start with generating autosign SSL certificate
#                  ./bat-nginx-helper.sh -r 2 -v mynewsite     (remove site and data, and certificate if https)
#
# Notes          : Need bash, grep, sed, nginx, openssl.
#                  Bash >= 4.0
#
#==============================#

set -e

# Load librares - Set PREFIX in command line
PREFIX=$(realpath $(dirname ${BASH_SOURCE[0]})/../)
LIB_DIR="$PREFIX/lib/bash-admin-toolkit"
CMD_DIR="$PREFIX/sbin"
source $LIB_DIR/common.lib.bash
source $LIB_DIR/color.lib.bash
source $LIB_DIR/keycert.lib.bash
source $LIB_DIR/nginx.lib.bash

# Define and get options
options=(["conf"]="" ["vhost"]="" ["domain"]="local" ["port"]="" ["ssl"]="autosign" ["overwrite"]="0"  ["remove"]="false" ["debug"]="0" ["quiet"]="1" ["force"]="0" ["safe-interactive"]="0" ["help"]="0") ;
m_opt=(["conf"]="conf" ["c"]="conf" ["vhost"]="vhost" ["v"]="vhost" ["domain"]="domain" ["D"]="domain" ["port"]="port" ["p"]="port" ["ssl"]="ssl" ["s"]="ssl" ["overwrite"]="overwrite"  ["o"]="overwrite"  ["remove"]="remove" ["r"]="remove" ["debug"]="debug" ["d"]="debug" ["quiet"]="quiet" ["q"]="quiet" ["force"]="force" ["f"]="force" ["safe-interactive"]="safe-interactive" ["i"]="safe-interactive"  ["help"]="help" ["h"]="help") ;
# And a last table to list environment variables with matching option CLI index (see function validate_env() in common.lib.bash)
env_variables=(["VHOST"]="vhost" ["DOMAIN"]="local" ["LISTEN_PORT"]="port" ["SSL"]="ssl" ["OVERWRITE"]="overwrite"  ["REMOVE_MODE"]="remove" ["DEBUG_LEVEL"]="debug" ["QUIET"]="quiet" ["FORCE"]="force" ["SAFE_INTERACTIVE"]="safe-interactive" ["HELP"]="help") ;

# Input values from args (means arguments or command line options)
get_options $@

if [ -n "$(grep -E '\.conf' <<< ${options['conf']})" -a -f ${options["conf"]} ] ;then
    # Input  values with sourcing .conf file
    source ${options["conf"]}
    fallback_env
else
    # Input values from environment variables (see documentation for syntax)
    validate_env
fi

log_info "$LAUNCHER_COMMAND"

# Other variables set
WEBROOT="/var/www/$VHOST/html"
LOGDIR="/var/www/$VHOST/logs"
NGINX_CONF="$SITES_AVAILABLE/$VHOST"
HOST_FILE="/etc/hosts"
HTTPS_PATTERN='.*443.*'
# Set messages
ERR_VHOST="postinstall-nginx failed : wrong argument for vhost"
ERR_PORT="postinstall-nginx failed : wrong argument for port"
ERR_DUPLICATED="postinstall-nginx failed : vhost already exist"
NGINX_VHOST_CREATED="NGINX vhost $VHOST created successfuly and available with \"http://$VHOST:$LISTEN_PORT\"."
NGINX_VHOST_REMOVED="NGINX vhost $VHOST removed successfuly."
NGINX_VHOST_ALREADY_REMOVED="NGINX vhost $VHOST doesn't exist. No action was necessary."

# Depending of Debug level you choosed, debug CLI options, and critical environment variables
debug_options
debug_env

[ "${options['help']}" == "1" ] && echo nginx_postinstall_help && exit 
# Check if vhost is provided
[ -z "$VHOST" ] && log_exit_on_failure $ERR_VHOST && echo nginx_postinstall_help && exit 

# Consider first remove options : if remove requested and site exists, remove site config, and data if 
if  [ "$REMOVE_MODE" != "false" ] ;then
    if [ "$(site_exists $NGINX_CONF)" == "1" ] ;then
	[[ "$(get_nginx_listen_port)" =~ $HTTPS_PATTERN ]] && safe_run_without_info "Certificate removed for $VHOST" remove_certificate $VHOST
	safe_run_without_info "Nginx virtual host removed: $VHOST." remove_site
	safe_run_without_info "Entry for $VHOST remove in $HOST_FILE." hosts_remove $VHOST
	log_success $NGINX_VHOST_REMOVED
    fi
    exit
fi 

# Doesn't overwrite
[ "${options['overwrite']}" == "0" -a "$(site_exists $VHOST)" == "1" ] && log_exit_on_failure $ERR_DUPLICATED && exit
# Error if port is missing
[ -z "$LISTEN_PORT" ] && log_exit_on_failure $ERR_PORT && nginx_postinstall_help && exit 

# Install nginx if necessary
safe_run_without_info "nginx install" install_service nginx
safe_run_without_info "nginx start" start_service nginx
# Create certificate for ssl
[[ "$LISTEN_PORT" =~ $HTTPS_PATTERN ]] && safe_run "certificate creation" autosign_certificate $VHOST $DOMAIN 365
# Add new site
safe_run_without_info "vhost $VHOST creation" create_site
safe_run_without_info "site $VHOST activation" activate_site
safe_run_without_info "addition of $VHOST" hosts_add $VHOST "# Nginx"
# Manage security
safe_run_without_info "addition of firewall rule" append_firewall_rules

# End
log_success $NGINX_VHOST_CREATED

