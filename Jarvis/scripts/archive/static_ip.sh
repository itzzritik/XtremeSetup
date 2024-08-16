#!/bin/bash -e

printf '\n+%131s+\n\n' | tr ' ' '-'
echo "⚪ Setting static ip address"
echo

# Check super user permission
if [ $(id -u) -ne 0 ];
then
  echo "⛔ This script needs to run WITH superuser permission!"
  exit 1
fi

Banner="#Jarvis Network Configuration"

if ! dpkg -l | grep -q openvswitch-switch; then
  echo "Open vSwitch is not installed. Installing..."
  sudo apt install -y openvswitch-switch
  echo
  echo
else
  echo "✔ Open vSwitch is already installed"
fi

ConfigBanner=$(sudo head -n 1 /etc/netplan/50-cloud-init.yaml)

if [[ "$ConfigBanner" == "$Banner"* ]]
then
  echo "✔ Static ip already set"
  exit 0
fi

sudo systemctl start openvswitch-switch

# Backup current configuration
sudo cp /etc/netplan/50-cloud-init.yaml /etc/netplan/50-cloud-init.yaml.bak
echo "Configuration backed up successfully"
# sudo mv /etc/netplan/50-cloud-init.yaml.bak /etc/netplan/50-cloud-init.yaml

sudo cp /etc/netplan/50-cloud-init.yaml.bak /etc/netplan/50-cloud-init.yaml.bak.bak

# Prompt for WiFi credentials and desired static ip
read -e -p "Enter your WiFi SSID: " -i "Ritik" ssid
read -e -p "Enter your WiFi password: " -i "VeryComplexPassword" password
read -e -p "Enter the desired static ip: " -i "192.168.68.255" IP
echo

CURRENT_ACTIVE_INTERFACE=$(ip route | grep default | awk '{print $5}')
ROUTER_IP=$(ip route | grep default | awk '{print $3}' | head -n 1)
DOMAIN_NAME_SERVER=$(awk '/nameserver/{dns=dns" "$2} END {sub(/^ */,"",dns); print dns}' < /etc/resolv.conf)

# Create new configuration
echo "$Banner

network:
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