#!/bin/bash -e

echo
echo "+-----------------------------------------------------------------------------------------------------------------------------------+"
echo
printf '⚪ Setting hostname as jarvis'
echo

# Take hostname input (hardcoding for now)
# read -e -p "Enter the desired hostname: " -i "jarvis" HOSTNAME
HOSTNAME="jarvis"

# Set the new hostname
sudo hostnamectl set-hostname $HOSTNAME

# Update the /etc/hosts file
IP_ADDRESS="127.0.1.1"
if grep -q "^$IP_ADDRESS\s*$HOSTNAME" /etc/hosts; then
    sudo sed -i "s/^$IP_ADDRESS\s*.*$/$IP_ADDRESS $HOSTNAME/" /etc/hosts
else
    echo -e "$IP_ADDRESS $HOSTNAME" | sudo tee -a /etc/hosts > /dev/null
fi

echo
echo "✔ Successfully set hostname as jarvis"