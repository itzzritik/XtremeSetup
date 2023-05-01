#!/bin/bash -e

# Check super user permission
if [ $(id -u) -ne 0 ];
then
  echo "⛔ This script needs to run WITH superuser permission!"
  exit 1
fi

echo "⚪ Setting static ip address"
echo

# Install dhcpcd5 if not installed already
if [ $(dpkg-query -W -f='${Status}' dhcpcd5 2>/dev/null | grep -c "ok installed") -eq 0 ];
then
  echo "⛔ Package \"dhcpcd5\" not found, Installing..."
  echo
  sudo apt install dhcpcd5 -y
  echo
fi

# Check if static ip is already configured in /etc/dhcpcd.conf file
if grep -q "Static IP Configuration for Jarvis" "/etc/dhcpcd.conf";
then
  echo "Static ip successfully already set!"
  exit 1
fi

# Request user to enter desired static ip
read -e -p "Enter the desired static ip: " -i "192.168.0.100" IP

# Write static ip configuration into /etc/dhcpcd.conf file
cat << EOF >> /etc/dhcpcd.conf

# Static IP Configuration for Jarvis
interface $(ip route | grep default | awk '{print $5}')
static ip_address=$IP/24
static routers=$(ip route | grep default | awk '{print $3}')
static domain_name_servers=$(awk '/nameserver/{dns=dns" "$2} END {sub(/^ */,"",dns); print dns}' < /etc/resolv.conf)
EOF

echo
echo "Static ip successfully set, Restart Raspberry Pi for changes to take effect."