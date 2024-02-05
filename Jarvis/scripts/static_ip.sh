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

# Set hostname as jarvis
echo "Setting hostname as jarvis"
read -e -p "Enter the desired hostname: " -i "jarvis" hostname
sudo hostnamectl set-hostname $hostname

# Prompt for WiFi credentials and desired static ip
read -p "Enter your WiFi SSID: " ssid
read -sp "Enter your WiFi password: " password
read -e -p "Enter the desired static ip: " -i "192.168.0.200" IP
echo

# Create new configuration
echo "network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: no
      addresses: [$IP/24]
      gateway4: 192.168.0.1
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]
  wifis:
    wlan0:
      dhcp4: no
      addresses: [$IP/24]
      gateway4: 192.168.0.1
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]
      access-points:
        \"$ssid\":
          password: \"$password\"
" | sudo tee /etc/netplan/50-cloud-init.yaml

# Apply the configuration
sudo netplan apply

echo
echo "Restart the device for changes to take effect."