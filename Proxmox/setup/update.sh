#!/bin/bash -e

printf '+%166s+\n' | tr ' ' '-'
printf "|%*s|\n" 166 " "
printf "|%75sUPDATING SYSTEM%76s|\n" "" ""
printf "|%*s|\n" 166 " "
printf '+%166s+\n\n' | tr ' ' '-'
echo -e "● Updating $(dmidecode -s system-product-name || echo "System")\n"

THRESHOLD=1
UPDATED_AT_FILE="$HOME/.jarvis/updated_at"
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

apt update -y
apt upgrade -y
apt autoremove -y
apt clean -y

mkdir -p "$(dirname "$UPDATED_AT_FILE")"
date +%s | tee "$UPDATED_AT_FILE" > /dev/null
echo -e "\n✔ System update completed\n"
