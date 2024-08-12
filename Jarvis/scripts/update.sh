#!/bin/bash -e

echo "+-----------------------------------------------------------------------------------------------------------------------------------+"
echo "|                                                                                                                                   |"
echo "|                                                          UPDATING SYSTEM                                                          |"
echo "|                                                                                                                                   |"
echo "+-----------------------------------------------------------------------------------------------------------------------------------+"
echo

DEVICE=$(tr -d '\0' </sys/firmware/devicetree/base/model || echo "System")

echo "⚪ Updating $DEVICE" && echo

[ $(id -u) -ne 0 ] && echo ⛔ This script needs to run WITH superuser permission! && exit 1

last_update=$(stat -c %Y /var/lib/apt/periodic/update-success-stamp)
current_time=$(date +%s)
time_difference=$(echo "($current_time - $last_update) / (60 * 60 * 24)" | bc)
threshold=1

[ ! $time_difference -gt $threshold ] && echo "✔ System already up to date" && exit 0

echo ""
echo ""
sudo apt update -y
sudo apt upgrade -y
sudo apt autoremove -y
echo ""
echo ""