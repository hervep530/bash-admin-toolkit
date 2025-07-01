#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# === CONFIGURATION ===
HOSTNAME="devuan-vps"
NEW_USER="your-admin"
SSH_PUBKEY="ssh-ed25519 AAAAC3Nz... your-real-ssh-key" # Replace it

echo "🔧 [1/9] System update"
apt update && apt upgrade -y
apt install -y apt-transport-https curl vim htop net-tools lsb-release ca-certificates gnupg mc sudo tree pstree bc

echo "🧹 [2/9] Cleaning : delete automatic update"
apt purge -y unattended-upgrades || true
apt autoremove -y

echo "🔐 [3/9] Sécurity SSH"
sed -i 's/^#\?PermitRootLogin .*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config
service ssh restart

echo "🛡️ [4/9] Install and set fail2ban"
apt install -y fail2ban
cat <<EOF > /etc/fail2ban/jail.local
[sshd]
enabled = true
port = 22
EOF
service fail2ban restart
update-rc.d fail2ban defaults

echo "🚧 [5/9] Install iptables with minimal rules"
apt install -y iptables iptables-persistent

iptables -F
iptables -X
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -p icmp --icmp-type 8 -j ACCEPT
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# SSH uniquement
iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -p tcp --sport 22 -m conntrack --ctstate ESTABLISHED -j ACCEPT

netfilter-persistent save

echo "👤 [6/9] Create user $NEW_USER with sudo access"
if ! id "$NEW_USER" &>/dev/null; then
  adduser "$NEW_USER"
  usermod -aG sudo "$NEW_USER"
fi

echo "🔑 [7/9] Add ssh key for $NEW_USER"
USER_HOME=$(eval echo ~$NEW_USER)
mkdir -p "$USER_HOME/.ssh"
echo "$SSH_PUBKEY" > "$USER_HOME/.ssh/authorized_keys"
chmod 700 "$USER_HOME/.ssh"
chmod 600 "$USER_HOME/.ssh/authorized_keys"
chown -R "$NEW_USER:$NEW_USER" "$USER_HOME/.ssh"

echo "📛 [8/9] Set hostname"
echo "$HOSTNAME" > /etc/hostname
hostname "$HOSTNAME"
grep -q "$HOSTNAME" /etc/hosts || echo "127.0.1.1 $HOSTNAME" >> /etc/hosts

echo "🧽 [9/9] Uninstall apache if already installed"
apt purge -y apache2 apache2-bin apache2-data apache2-utils || true

echo "✅ Post-install is finished. Reboot is recommanded after testing ssh connexion with new account."


