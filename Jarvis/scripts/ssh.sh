#!/bin/bash -e

echo
echo "+-----------------------------------------------------------------------------------------------------------------------------------+"
echo
echo "⚪ Setting ssh key to \".ssh/authorized_keys\""
echo

# Check super user permission
if [ $(id -u) -eq 0 ]; then
  echo "⛔ This script needs to run WITHOUT superuser permission"
  exit 1
fi

while read -r line
do
  if [[ $line == *"HVJW2" ]]; then
    echo "✔ Authorized SSH key already set"
    exit 0
  fi
done < $HOME/.ssh/authorized_keys

# Input ssh public key
read -p "Enter the ssh public key: " KEY

# write and repalce the ssh key into /home/ritik/.ssh/authorized_keys file
if [ "$KEY" != "" ]; then
   echo $KEY > /home/ritik/.ssh/authorized_keys
fi

echo
echo "✔ Successfully added ssh key"