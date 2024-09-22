#!/bin/bash -e

printf '\n+%131s+\n\n' | tr ' ' '-'
echo -e "● Setup configurations\n"

BASE_DIR="$HOME/.$JARVIS_HOSTNAME"
CONFIG_REPO="git@github.com:itzzjarvis/configs.git"

echo "→ Init config and log directories"
mkdir -p "$JARVIS_CONFIGS" "$JARVIS_LOGS"
rm -rf "$JARVIS_LOGS"/*

if [ ! -d "$JARVIS_CONFIGS/.git" ]; then
	echo -e "→ Fetch and restore configurations\n"
	git clone "$CONFIG_REPO" "$JARVIS_CONFIGS" || { echo "✕ Failed to fetch configurations"; exit 1; }
	echo
fi

echo -e "→ Setting up permissions"
sudo chown -R $USER:$USER "$BASE_DIR"
sudo chmod -R 777 "$BASE_DIR"

echo "→ Cleanup empty directories"
find "$BASE_DIR" -mindepth 1 -maxdepth 1 -type d -empty -exec rmdir {} +