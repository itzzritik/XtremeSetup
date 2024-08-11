#!/bin/bash

echo
echo "+-----------------------------------------------------------------------------------------------------------------------------------+"
echo
printf '⚪ Setting timezone as IST (Asia/Kolkata)'
echo

if [ $(id -u) -eq 0 ]; then
  echo "⛔ This script needs to run WITHOUT superuser permission" & exit 1
fi

CURRENT_TIMEZONE="Asia/Kolkata"

if [ "$(timedatectl | grep 'Time zone' | awk '{print $3}')" == "$CURRENT_TIMEZONE" ]; then
    echo "✔ Timezone is already set to $CURRENT_TIMEZONE." & exit 1
fi

sudo timedatectl set-timezone $CURRENT_TIMEZONE
sudo systemctl restart systemd-timesyncd

if [ "$(timedatectl | grep 'Time zone' | awk '{print $3}')" != "$CURRENT_TIMEZONE" ]; then
    echo "⛔ Failed to set timezone." & exit 1
fi

echo "✔ Timezone successfully set to $CURRENT_TIMEZONE."