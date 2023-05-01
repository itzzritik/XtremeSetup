#!/bin/bash -e

# Check super user permission
if [ $(id -u) -eq 0 ];
then
   echo "⛔ This script needs to run WITHOUT superuser permission"
   exit 1
fi

echo "⚪ Setting ssh key to \".ssh/authorized_keys\""
echo

# Input ssh public key
read -p "Enter the ssh public key: " KEY

# write and repalce the ssh key into /home/ritik/.ssh/authorized_keys file
if [ "$KEY" != "" ];
then
   echo $KEY > /home/ritik/.ssh/authorized_keys
fi

echo
echo "Successfully added ssh key."