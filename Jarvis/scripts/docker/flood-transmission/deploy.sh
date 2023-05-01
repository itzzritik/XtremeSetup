#!/bin/bash -e

# Check super user permission
if [ $(id -u) -ne 0 ];
then
    echo ⛔ This script needs to run WITH superuser permission!
    exit 1
fi

printf '⚪ Deploying \e]8;;https://flood.js.org\e\\Flood\e]8;;\e\\ and \e]8;;https://transmissionbt.com\e\\Transmission\e]8;;\e\\ in Docker\n'
echo

# Install jq if not installed already
if [ $(dpkg-query -W -f='${Status}' jq 2>/dev/null | grep -c "ok installed") -eq 0 ];
then
    echo "⛔ Package \"jq\" not found, Installing..."
    echo
    sudo apt install jq -y
    echo
fi

# Install docker if not installed already
if ! [[ $(which docker) && $(docker --version) ]];
then
    echo "⛔ \"Docker\" not found, Installing..."
    sudo bash ./scripts/docker/docker_setup.sh
    echo
fi

SCRIPT_DIR=$(realpath "$(dirname "${BASH_SOURCE[0]}")")
CONFIG_DIR="/media/drive1/.config/torrent"
SETTINGS_JSON="$CONFIG_DIR/settings.json"

# Write .env file for docker compose
sudo echo "PUID=$(id -u ritik)
PGID=$(id -g ritik)" | tee .env > /dev/null

echo "→ Removing existing containers"
echo
docker compose -f $SCRIPT_DIR/compose.yml rm -s -f
echo
echo "→ Deploying new containers"
echo
docker compose -f $SCRIPT_DIR/compose.yml up -d
echo
read -r -p "→ Setting up torrent configurations" -t 2 -n 1 -s
echo
echo
docker compose -f $SCRIPT_DIR/compose.yml stop
echo
sudo cat <<< $(jq '."download-dir"="/downloads" | ."incomplete-dir"="/downloads/.incomplete"' "$SETTINGS_JSON") > $SETTINGS_JSON
docker compose -f $SCRIPT_DIR/compose.yml start
echo
read -r -p "→ Finalizing your settings" -t 5 -n 1 -s
echo
echo
sudo rm -rf /media/drive1/Downloads/Torrent/complete /media/drive1/Downloads/Torrent/incomplete
echo
echo "Transmission installed successfully."


