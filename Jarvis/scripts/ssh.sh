#!/bin/bash -e

printf '\n+%131s+\n\n' | tr ' ' '-'
echo -e "● Setting ssh key to \".ssh/authorized_keys\"\n"

if [ $(id -u) -eq 0 ]; then
  echo "✕ This script needs to run WITHOUT superuser permission" && exit 1
fi

while read -r line
do [[ $line == *"HVJW2" ]] && echo "✔ Authorized SSH key already set" && exit 0
done < $HOME/.ssh/authorized_keys

read -p "Enter the ssh public key: " KEY

if [ "$KEY" != "" ]; then
  echo $KEY > /home/ritik/.ssh/authorized_keys
fi

echo "✔ Successfully added ssh key"