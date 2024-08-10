#!/bin/bash -e

echo
echo "+-----------------------------------------------------------------------------------------------------------------------------------+"
echo
printf '⚪ Setting hostname as jarvis'
echo

# Exit if /etc/hosts file contains the word "jarvis"
if grep -q "jarvis" /etc/hosts; then
    echo "✔ Hostname already set as jarvis"
    exit 1
fi

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


# /etc/hosts file
# 127.0.1.1 jarvis jarvis
# 127.0.0.1 localhost

# ::1 localhost ip6-localhost ip6-loopback
# ff02::1 ip6-allnodes
# ff02::2 ip6-allrouters