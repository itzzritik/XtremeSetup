#!/bin/bash -e

# Check super user permission
if [ $(id -u) -ne 0 ];
then
    echo ⛔ This script needs to run WITH superuser permission!
    exit 1
fi

echo '⚪ Deploying Media Server in Docker'
printf '1. \e]8;;https://jellyfin.org\e\\Jellyfin\e]8;;\e\\\n'
printf '1. \e]8;;https://jellyfin.org\e\\Jellyfin\e]8;;\e\\\n'
printf '1. \e]8;;https://jellyfin.org\e\\Jellyfin\e]8;;\e\\\n'
echo

# Install docker if not installed already
if ! [[ $(which docker) && $(docker --version) ]];
then
    echo "⛔ \"Docker\" not found, Installing..."
    sudo bash ./scripts/docker/docker_setup.sh
    echo
fi

SCRIPT_DIR=$(realpath "$(dirname "${BASH_SOURCE[0]}")")
MEDIA_ROOT="/media/drive1"

# Write .env file for docker compose
sudo echo "
PUID=$(id -u ritik)
PGID=$(id -g ritik)
TZ=Asia/Kolkata
" | tee .env > /dev/null

echo "→ Removing existing containers"
echo
docker compose -f $SCRIPT_DIR/compose.yml rm -s -f
echo
echo "→ Deploying new containers"
echo
docker compose -f $SCRIPT_DIR/compose.yml up -d
echo
echo "Media Server installed successfully."


