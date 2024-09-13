#!/bin/bash

printf '\n+%131s+\n\n' | tr ' ' '-'
echo -e '● Setting system timezone\n'

[ $(id -u) -eq 0 ] && echo "✕ This script needs to run WITHOUT superuser permission" && exit 1

[ "$(timedatectl | grep 'Time zone' | awk '{print $3}')" == "$JARVIS_TZ" ] && echo "✔ Timezone is already set to $JARVIS_TZ" && exit 0

sudo timedatectl set-timezone $JARVIS_TZ
sudo systemctl restart systemd-timesyncd

[ "$(timedatectl | grep 'Time zone' | awk '{print $3}')" != "$JARVIS_TZ" ] && echo "✕ Failed to set timezone" && exit 1

echo "✔ Timezone successfully set to $JARVIS_TZ"