#!/bin/bash -e

printf '\n+%131s+\n\n' | tr ' ' '-'
echo -e "⚪ Setting static ip for Jarvis\n"

[ $(id -u) -eq 0 ] && echo "⛔ This script needs to run WITHOUT superuser permission" && exit 1

GATEWAY="192.168.68.1"
CONFIG_FILE="/etc/netplan/static.yaml"
CURRENT_IP=$(sudo grep -A 1 "addresses:" "$CONFIG_FILE" 2>/dev/null | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -n 1 || echo "")

[[ "$CURRENT_IP" == "$JARVIS_STATIC_IP" ]] && echo "✔ Static IP is already set to $JARVIS_STATIC_IP" && exit 0

sudo tee "$CONFIG_FILE" >/dev/null <<EOL
network:
  version: 2
  ethernets:
    eth0:
      addresses:
        - $JARVIS_STATIC_IP/24
      routes:
        - to: default
          via: $GATEWAY
      nameservers:
        addresses:
          - $(echo "$JARVIS_GOOGLE_DNS" | sed 's/;/\n          - /')
      dhcp4: no
EOL

echo "✔ Netplan configuration updated. applying changes..."
sudo chmod 600 "$CONFIG_FILE"
sudo netplan apply
echo "✔ Netplan changes applied successfully"
