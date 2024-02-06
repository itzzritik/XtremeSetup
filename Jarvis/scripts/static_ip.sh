#!/bin/bash -e

# Check super user permission
if [ $(id -u) -ne 0 ];
then
  echo "⛔ This script needs to run WITH superuser permission!"
  exit 1
fi

echo "⚪ Setting static ip address"
echo

# Backup current configuration
sudo cp /etc/netplan/50-cloud-init.yaml /etc/netplan/50-cloud-init.yaml.bak
echo "Configuration backed up successfully"
# sudo mv /etc/netplan/50-cloud-init.yaml.bak /etc/netplan/50-cloud-init.yaml

sudo cp /etc/netplan/50-cloud-init.yaml.bak /etc/netplan/50-cloud-init.yaml.bak.bak

# Set hostname as jarvis
echo "Setting hostname as jarvis"
read -e -p "Enter the desired hostname: " -i "jarvis" hostname
sudo hostnamectl set-hostname $hostname

# Prompt for WiFi credentials and desired static ip
read -e -p "Enter your WiFi SSID: " -i "ACTFIBERNET_5G" ssid
read -p "Enter your WiFi password: " password
read -e -p "Enter the desired static ip: " -i "192.168.0.200" IP
echo

CURRENT_ACTIVE_INTERFACE=$(ip route | grep default | awk '{print $5}')
ROUTER_IP=$(ip route | grep default | awk '{print $3}' | head -n 1)
DOMAIN_NAME_SERVER=$(awk '/nameserver/{dns=dns" "$2} END {sub(/^ */,"",dns); print dns}' < /etc/resolv.conf)

# Create new configuration
echo "network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: no
      addresses: [$IP/24]
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]
      routes:
        - to: 0.0.0.0/0
          via: $ROUTER_IP
  wifis:
    wlan0:
      dhcp4: no
      addresses: [$IP/24]
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]
      access-points:
        \"$ssid\":
          password: \"$password\"
      routes:
        - to: 0.0.0.0/0
          via: $ROUTER_IP
          metric: 200
      
" | sudo tee /etc/netplan/50-cloud-init.yaml > /dev/null

# Apply the configuration
sudo netplan apply

echo
echo "New connection settings has been applied"