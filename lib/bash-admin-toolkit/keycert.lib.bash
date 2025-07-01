# keycert.lib.bash : functions to manage key and certificates

# Generates autosign certificate
function autosign_certificate() {

    if (( $# != 3 )) ;then
	echo "[x] Autosign certificate failed - wrong arguments"
	exit 1
    fi

    if (( $# == 3 )) ;then
        echo "[i] test parameters OK"
    fi

    vhost=$1
    domain=$2
    duration=$3

    echo "[+] Generate ssl certificate..."
    sudo openssl req -x509 -nodes -days $duration -newkey rsa:2048 \
      -keyout /etc/ssl/private/${vhost}.key \
      -out /etc/ssl/certs/${vhost}.crt \
      -subj "/CN=${vhost}.$domain"
}

# Remove certificate
function remove_certificate() {
    vhost=$1
    
    if [ ! -f /etc/ssl/private/${vhost}.key ] ;then
	echo "[x] SSL certificate doesn't exists"
    fi
    echo "[-] Remove ssl certificate..."
    rm /etc/ssl/private/${vhost}.*
}

# Import ssh key
function import_ssh_key() {
    #### First, generate keys for user to allows on the remote client ####
    # ssh-keygen -t ed25519 -f ~/.ssh/$user -C $decription

    # Config
    username=$1
    ssh_pubkey=$2

    user_home=$(eval echo ~$username)
    IFS=" " read -r -a group_list <<< $(eval "groups $username | sed -e 's/$username\s*:*\s*//g'")
    user_group=${group_list[0]}

    # Import
    mkdir -p "$user_home/.ssh"
    echo "$ssh_pubkey" > "$user_home/.ssh/authorized_keys"
    chmod 700 "$user_home/.ssh"
    chmod 600 "$user_home/.ssh/authorized_keys"
    chown -R "$username:$user_group" "$user_home/.ssh"

    echo "🔑 Install_ssh_key() [1/1] - SSH for $username"
}

