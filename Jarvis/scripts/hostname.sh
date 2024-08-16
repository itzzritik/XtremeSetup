#!/bin/bash -e

printf '\n+%131s+\n\n' | tr ' ' '-'
printf '⚪ Setting hostname as jarvis\n'
echo

HOSTNAME="jarvis"

if grep -q "$HOSTNAME" /etc/hosts; then
    echo "✔ Hostname already set as $HOSTNAME" && exit 0
fi

sudo hostnamectl set-hostname $HOSTNAME

echo "
127.0.1.1 jarvis jarvis
127.0.0.1 localhost

::1 localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
" | tee /etc/hosts > /dev/null

echo
echo "✔ Successfully set hostname as jarvis"