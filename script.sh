#!/bin/bash

print_banner() {
  local name="$1"
  local contact="$2"
  local width=$(tput cols)

  if [ "$width" -lt 60 ]; then
    width=60
  fi

  local border=$(printf '%*s' "$width" '' | tr ' ' '*')
  local empty_line="*$(printf '%*s' $((width-2)) '')*"

  echo "$border"
  echo "$empty_line"

  center_text() {
    local text="$1"
    local text_len=${#text}
    local padding=$(((width - 2 - text_len) / 2))
    local extra=$(((width - 2 - text_len) % 2))
    if [ $padding -lt 0 ]; then
      printf "* %s *\n" "$text"
    else
      printf "*%*s%s%*s*\n" $padding "" "$text" $((padding + extra)) ""
    fi
  }

  center_text "Déploiement Serveur VPN avec Interface WGDashboard"
  echo "$empty_line"
  center_text "Réalisé par $name"
  echo "$empty_line"
  center_text "Contact : $contact"
  echo "$empty_line"
  echo "$border"
}

print_banner "Stanislas THABAULT" "https://www.linkedin.com/in/stanislas-thabault/"

echo
read -p "🟢 Entrez le nom de l'utilisateur non-root (ex: vpn): " UTILISATEUR

if [ ! -d "/home/$UTILISATEUR" ]; then
    echo
    echo "Erreur : /home/$UTILISATEUR n'existe pas. Veuillez vérifier le nom de l'utilisateur."
    exit 1
fi

# Mise à jour
echo
echo "🟢 Mise à jour du système..."
echo
sudo dnf update -y
sudo dnf upgrade -y

# Installation des paquets nécessaires
echo
echo "🟢 Installation de Wireguard-Tools, Firewalld, Net-Tools, Git, Systemd-Resolved et Python3.11..."
echo
sudo dnf install wireguard-tools firewalld net-tools git systemd-resolved python3.11 -y

# Clonage du dépôt WGDashboard
echo
echo "🟢 Clone du dépôt et installation de WGDashboard..."
echo
sudo -u "$UTILISATEUR" git clone https://github.com/donaldzou/WGDashboard.git "/home/$UTILISATEUR/WGDashboard"
cd "/home/$UTILISATEUR/WGDashboard/src"
chmod +x ./wgd.sh
sudo -u "$UTILISATEUR" ./wgd.sh install

# Configuration de l'interface wg0
WG_PATH="/etc/wireguard/wg0.conf"

sudo wg genkey | sudo tee "/etc/wireguard/server.key" | wg pubkey | sudo tee "/etc/wireguard/server.pub"

PRIVATE_KEY=$(cat /etc/wireguard/server.key)

cat <<EOF | sudo tee $WG_PATH > /dev/null
[Interface]
Address = 10.0.0.1/24
SaveConfig = false
ListenPort = 51820
PrivateKey = $PRIVATE_KEY
EOF

# Configuration Forwarding et règles de pare-feu
echo
echo "🟢 Configuration de Forwarding et des règles de pare-feu..."
echo
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf > /dev/null
sudo sysctl -p /etc/sysctl.conf
sudo firewall-cmd --add-port=10086/tcp --permanent
sudo firewall-cmd --add-port=51820/udp --permanent
sudo firewall-cmd --add-masquerade --permanent
sudo firewall-cmd --zone=public --add-interface=wg0 --permanent
sudo firewall-cmd --reload
sudo semanage fcontext -a -t bin_t "/home/vpn/WGDashboard/src/venv/bin(/.*)?"
sudo semanage port -a -t openvpn_port_t -p udp 51820 2>/dev/null || sudo semanage port -m -t openvpn_port_t -p udp 51820
sudo semanage port -a -t http_port_t -p tcp 10086 2>/dev/null || sudo semanage port -m -t http_port_t -p tcp 10086
sudo restorecon -Rv /home/vpn/WGDashboard/src/venv/bin/
sudo restorecon -Rv /home/$UTILISATEUR/WGDashboard
sudo restorecon -Rv /etc/wireguard

# Création du service systemd
echo
echo "🟢 Création du Service WGDashboard..."
echo

SERVICE_PATH="/etc/systemd/system/vpn.service"

cat <<EOF | sudo tee $SERVICE_PATH > /dev/null
[Unit]
Description=WG Dashboard Gunicorn Service
After=network.target

[Service]
Type=forking
User=root
Group=root
WorkingDirectory=/home/$UTILISATEUR/WGDashboard/src
ExecStart=/home/$UTILISATEUR/WGDashboard/src/venv/bin/gunicorn --config /home/$UTILISATEUR/WGDashboard/src/gunicorn.conf.py
Restart=always
KillMode=process

[Install]
WantedBy=multi-user.target
EOF

# Activation et démarrage des services
echo
echo "🟢 Actualisation des services..."
echo
sudo systemctl daemon-reload

echo
echo "🟢 Démarrage du service WGDashboard..."
echo
sudo systemctl enable vpn.service
sudo systemctl start vpn.service

echo
echo "🟢 Démarrage du service Wireguard avec la configuration wg0..."
echo
sudo systemctl enable wg-quick@wg0
sudo systemctl start wg-quick@wg0

echo
echo "✅ Déploiement terminé."
echo