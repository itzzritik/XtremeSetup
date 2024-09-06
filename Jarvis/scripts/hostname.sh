#!/bin/bash -e

printf '\n+%131s+\n\n' | tr ' ' '-'
echo '⚪ Setting hostname as jarvis'
echo

REQUIRED_VARS=(
  "JARVIS_HOSTNAME"
)
for VAR in "${REQUIRED_VARS[@]}"; do [ -z "${!VAR}" ] && echo "⛔ Env variable \"$VAR\" not set!" && exit 1; done

if grep -q "$JARVIS_HOSTNAME" /etc/hosts; then
    echo "✔ Hostname already set as $JARVIS_HOSTNAME" && exit 0
fi

sudo hostnamectl set-hostname $JARVIS_HOSTNAME

echo "
127.0.1.1 jarvis jarvis
127.0.0.1 localhost

::1 localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
" | tee /etc/hosts > /dev/null

echo
echo "✔ Successfully set hostname as jarvis"