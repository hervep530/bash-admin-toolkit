#!/bin/bash
#
# Filename       : bat-nginx-helper.sh
# Description    : after getting command line arguments, add or remove nginx site (config + test page + ssl certificate).
# Author         : Hervé Pineau - Copyright [2025]
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
source $LIB_DIR/keycert.lib.bash
source $LIB_DIR/nginx.lib.bash

# Define and get options
options=(["conf"]="" ["vhost"]="" ["domain"]="local" ["port"]="" ["ssl"]="autosign" ["overwrite"]="0"  ["remove"]="false" ["debug"]="0" ["help"]="0") ;
m_opt=(["conf"]="conf" ["c"]="conf" ["vhost"]="vhost" ["v"]="vhost" ["domain"]="domain" ["D"]="domain" ["port"]="port" ["p"]="port" ["ssl"]="ssl" ["s"]="ssl" ["overwrite"]="overwrite"  ["o"]="overwrite"  ["remove"]="remove" ["r"]="remove" ["debug"]="debug" ["d"]="debug" ["help"]="help" ["h"]="help") ;
get_options $@

# Set values from cmdline options
if [ -n "$(grep -E '\.conf' <<< ${options['conf']})" -a -f ${options["conf"]} ] ;then
    source ${options["conf"]}
    echo "$VHOST / $DOMAIN / $LISTEN_PORT / $REMOVE_MODE"
else
    [[ "$REMOVE_MODE" != "" ]] || REMOVE_MODE=${options["remove"]}
    [[ "$VHOST" != "" ]] || VHOST=${options["vhost"]}
    [[ "$DOMAIN" != "" ]] || DOMAIN=${options["domain"]}
    [[ "$LISTEN_PORT" != "" ]] || LISTEN_PORT=${options["port"]}
fi
WEBROOT="/var/www/$VHOST/html"
LOGDIR="/var/www/$VHOST/logs"
NGINX_CONF="$SITES_AVAILABLE/$VHOST"
HOST_FILE="/etc/hosts"
HTTPS_PATTERN='.*443.*'
# Set messages
ERR_VHOST="[x] postinstall-nginx failed : wrong argument for vhost"
ERR_PORT="[x] postinstall-nginx failed : wrong argument for port"
ERR_DUPLICATED="[x] postinstall-nginx failed : vhost already exist"
NGINX_SUCCESS="[✔] NGINX est installé, configuré, et accessible sur http://localhost:$LISTEN_PORT ou via IP"

[ "${options['help']}" == "1" ] && echo nginx_postinstall_help && exit 
# Check if vhost is provided
[ -z "$VHOST" ] && echo $ERR_VHOST && echo nginx_postinstall_help && exit 

# Consider first remove options : if remove requested and site exists, remove site config, and data if 
if  [ "$REMOVE_MODE" != "false" ] ;then
    if [ "$(site_exists $NGINX_CONF)" == "1" ] ;then
	[[ "$(get_nginx_listen_port)" =~ $HTTPS_PATTERN ]] && remove_certificate $VHOST
	remove_site
	hosts_remove $VHOST
    fi
    exit
fi 

# Doesn't overwrite
[ "${options['overwrite']}" == "0" -a "$(site_exists $VHOST)" == "1" ] && echo $ERR_DUPLICATED && exit
# Error if port is missing
[ -z "$LISTEN_PORT" ] && echo $ERR_PORT && nginx_postinstall_help && exit 

# Install nginx if necessary
install_service nginx
start_service nginx
# Create certificate for ssl
[[ "$LISTEN_PORT" =~ $HTTPS_PATTERN ]] && autosign_certificate $VHOST $DOMAIN 365
# Add new site
create_site
activate_site
hosts_add $VHOST "# Nginx"
# Manage security
append_firewall_rules

# End
echo $NGINX_SUCCESS
