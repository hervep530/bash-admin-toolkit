# nginx.lib.bash : Functions for install and settings for nginx

NGINX_CONF_DIR="/etc/nginx"
SITES_AVAILABLE="$NGINX_CONF_DIR/sites-available"
SITES_ENABLED="$NGINX_CONF_DIR/sites-enabled"

# Test if nginx site exists
function site_exists() {
    if [ -f $NGINX_CONF ] ;then
		echo 1
    else
		echo 0
    fi
}

# Get listen port in nginx conf (default 80 if not found)
function get_nginx_listen_port() {
    if [ -n $NGINX_CONF -a -f $NGINX_CONF ] ;then
		grep -E "listen\s*[0-9]+\s*" $NGINX_CONF | sed -e 's/.*listen\s*\([0-9]\+\).*/\1/g' 
    else
		echo "80"
    fi
}

# Config new site in Nginx 
function create_site() {	
	log_debug 2 "[+] Create web folders..."
	safe_run_without_success "write of $NGINX_CONF" mkdir -p "$WEBROOT" "$LOGDIR"

	log_debug 2 "[+] Create index page for test..."
	[ -f $WEBROOT/index.html ] || safe_run_without_success "sample index creation" echo "<h1>Http web site test : $VHOST</h1>" > "$WEBROOT/index.html"

	log_debug 2 "[+] Set new virtual host in Nginx : $VHOST..."
	http_pattern='.*80.*'
    if [[ "$LISTEN_PORT" =~ $http_pattern ]] ;then
	    safe_run_without_success "write of $NGINX_CONF" write_conf_without_ssl
	        else
	    safe_run_without_success "write of $NGINX_CONF" write_conf_with_ssl
    fi
}

function write_conf_without_ssl() {
	[ -f $NGINX_CONF ] || cat <<EOF > "$NGINX_CONF"
server {
    listen $LISTEN_PORT;
    listen [::]:$LISTEN_PORT;

    server_name $VHOST $VHOST.$DOMAIN www.$VHOST.$DOMAIN;

    root $WEBROOT;
    index index.html index.htm;

    access_log $LOGDIR/access.log;
    error_log $LOGDIR/error.log;

    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOF
}

function write_conf_with_ssl() {
	[ -f $NGINX_CONF ] || cat <<EOF > "$NGINX_CONF"
server {
    listen $LISTEN_PORT ssl;
    server_name $VHOST $VHOST.$DOMAIN www.$VHOST.$DOMAIN;

    ssl_certificate /etc/ssl/certs/$VHOST.crt;
    ssl_certificate_key /etc/ssl/private/$VHOST.key;

    root $WEBROOT;
    index index.html index.htm;

    access_log $LOGDIR/access.log;
    error_log $LOGDIR/error.log;

    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOF
}

# Activate Nginx site
function activate_site() {
	log_debug 2 "[+] Enable nginx virtual host..."
	[ -f $SITES_ENABLED/$VHOST ] || ln -sf $NGINX_CONF $SITES_ENABLED/$VHOST

	log_debug 2 "[+] Check nginx settings..."
	safe_run_without_success "nginx settings check" nginx -t

	log_debug 2 "[+] Restart nginx (SysVinit)..."
	safe_run_without_success "restart of nginx service" start_service nginx
}

# Remove site
function remove_site() {
	# Parameters
	webroot=$(grep "root" $NGINX_CONF | sed -e 's/.*root\s*\(\/.*\)\s*\;/\1/g')
	logdir=$(grep "error_log" $NGINX_CONF | sed -e 's/.*error_log\s*\(\/.*\)\/[^/]*\.log.*/\1/g')

	log_debug 2 "[-] Remove nginx site config..."
	[ -f $SITES_ENABLED/$VHOST ] && rm $SITES_ENABLED/$VHOST
	[ -f $NGINX_CONF ] && rm $NGINX_CONF
	safe_run_without_success "restart of nginx service" start_service nginx

    if [ "$REMOVE_MODE" == "data" ] ;then
        log_debug 2 "[-] Remove site data..."
        safe_run_without_success "site data removal" rm -r $webroot $logdir
	fi
}

# Set Firewall rules
function append_firewall_rules() {
	log_debug 2 "[+] Add iptables rules for port ${LISTEN_PORT}..."

	iptables -C INPUT -p tcp --dport $LISTEN_PORT -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT 2>/dev/null || \
	iptables -A INPUT -p tcp --dport $LISTEN_PORT -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT

	iptables -C OUTPUT -p tcp --sport $LISTEN_PORT -m conntrack --ctstate ESTABLISHED -j ACCEPT 2>/dev/null || \
	iptables -A OUTPUT -p tcp --sport $LISTEN_PORT -m conntrack --ctstate ESTABLISHED -j ACCEPT

	safe_run_without_success "save of iptables rules" netfilter-persistent save
}

# Display help
function nginx_helper_help() {
	echo "[?] TODO - How to use postinstall-nginx.sh"
}


