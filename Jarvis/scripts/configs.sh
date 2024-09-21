#!/bin/bash -e

printf '\n+%131s+\n\n' | tr ' ' '-'
echo -e "● Setup configurations\n"

CONFIG_REPO="git@github.com:itzzjarvis/configs.git"

echo "→ Init logs directory"
mkdir -p "$JARVIS_LOGS"
rm -rf "$JARVIS_LOGS"/*

echo "→ Fetch and restore configurations"
[ ! -d "$JARVIS_CONFIGS" ] && git clone "$CONFIG_REPO" "$JARVIS_CONFIGS" || { echo "✕ Failed to fetch configurations"; exit 1; }

echo "→ Setting up permissions"
sudo chown -R $USER:$USER "$HOME/.$JARVIS_HOSTNAME"
sudo chmod -R 777 "$HOME/.$JARVIS_HOSTNAME"

echo "→ Cleanup empty directories"
find "$JARVIS_CONFIGS" -mindepth 1 -maxdepth 1 -type d -empty -exec rmdir {} +
find "$JARVIS_LOGS" -mindepth 1 -maxdepth 1 -type d -empty -exec rmdir {} +