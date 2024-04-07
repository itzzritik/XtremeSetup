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
sed -i "s/127.0.0.1.*localhost/127.0.0.1\tlocalhost $HOSTNAME/" /etc/hosts