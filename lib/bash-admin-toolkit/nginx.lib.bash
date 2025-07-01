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

# Config new site in Nginx 
function create_site() {

	echo "[+] Create web folders..."
	mkdir -p "$WEBROOT" "$LOGDIR"

	echo "[+] Create index page for test..."
	[ -f $WEBROOT/index.html ] || echo "<h1>Http web site test : $VHOST</h1>" > "$WEBROOT/index.html"

	echo "[+] Set new virtual host in Nginx : $VHOST..."
	http_pattern='.*80.*'
        if [[ "$LISTEN_PORT" =~ $http_pattern ]] ;then
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
        else
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

# Remove site
function remove_site() {

	# Parameters
	webroot=$(grep "root" $NGINX_CONF | sed -e 's/.*root\s*\(\/.*\)\s*\;/\1/g')
	logdir=$(grep "error_log" $NGINX_CONF | sed -e 's/.*error_log\s*\(\/.*\)\/[^/]*\.log.*/\1/g')

	echo "[-] Remove nginx site config..."
	[ -f  ] && rm $SITES_ENABLED/$VHOST
	[ -f $NGINX_CONF ] && rm $NGINX_CONF
	service nginx restart

        if [ "$REMOVE_MODE" == "data" ] ;then
	   echo "[-] Remove site data..."
           rm -r $webroot $logdir
	fi

}

# Activate Nginx site
function activate_site() {

	echo "[+] Activation du site..."
	[ -f $SITES_ENABLED/$VHOST ] || ln -sf $NGINX_CONF $SITES_ENABLED/$VHOST

	echo "[+] Vérification de la configuration nginx..."
	nginx -t

	echo "[+] Démarrage de nginx (SysVinit)..."
	service nginx restart
	update-rc.d nginx defaults

}

# Set Firewall rules
function append_firewall_rules() {

	echo "[+] Ajout des règles iptables pour le port ${LISTEN_PORT}..."

	iptables -C INPUT -p tcp --dport $LISTEN_PORT -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT 2>/dev/null || \
	iptables -A INPUT -p tcp --dport $LISTEN_PORT -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT

	iptables -C OUTPUT -p tcp --sport $LISTEN_PORT -m conntrack --ctstate ESTABLISHED -j ACCEPT 2>/dev/null || \
	iptables -A OUTPUT -p tcp --sport $LISTEN_PORT -m conntrack --ctstate ESTABLISHED -j ACCEPT

	echo "[+] Sauvegarde des règles iptables..."
	netfilter-persistent save

}

# Display help
function nginx_postinstall_help() {
	echo "[?] TODO - How to use postinstall-nginx.sh"
}


