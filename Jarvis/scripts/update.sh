#!/bin/bash -e

printf '+%131s+\n' | tr ' ' '-'
echo "|                                                                                                                                   |"
echo "|                                                          UPDATING SYSTEM                                                          |"
echo "|                                                                                                                                   |"
printf '+%131s+\n\n' | tr ' ' '-'
echo -e "⚪ Updating $(tr -d '\0' </sys/firmware/devicetree/base/model || echo "System")\n"

[ $(id -u) -ne 0 ] && echo ⛔ This script needs to run WITH superuser permission! && exit 1

THRESHOLD=1
UPDATED_AT_FILE="/etc/jarvis/.updated_at"
LAST_UPDATED=$(cat "$UPDATED_AT_FILE" 2>/dev/null || echo 0)
CURRENT_TIME=$(date +%s)
DIFF=$((CURRENT_TIME - LAST_UPDATED))

DAYS=$((DIFF / 86400))
HOURS=$(((DIFF % 86400) / 3600))
MINUTES=$(((DIFF % 3600) / 60))

if [ "$DAYS" -le "$THRESHOLD" ]; then
    echo "✔ System was last updated $([ "$HOURS" -gt 0 ] && echo "$HOURS hrs and " || echo "")$MINUTES minutes ago" && exit 0
fi

echo -e "→ Performing system update\n"

sudo apt update -y
sudo apt upgrade -y
sudo apt autoremove -y
sudo apt clean -y

sudo mkdir -p "$(dirname "$UPDATED_AT_FILE")"
date +%s | sudo tee "$UPDATED_AT_FILE" > /dev/null
echo -e "\n✔ System update completed\n"
