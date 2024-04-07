#!/bin/bash -e

echo
echo "+-----------------------------------------------------------------------------------------------------------------------------------+"
echo
printf '⚪ Deploying \e]8;;https://www.home-assistant.io/\e\\HomeAssistant\e]8;;\e\\ in Docker\n'
echo

# Check super user permission
if [ $(id -u) -ne 0 ]; then
  echo ⛔ This script needs to run WITH superuser permission!
  exit 1
fi

# Install docker if not installed already
if ! [[ $(which docker) && $(docker --version) ]];
then
    echo "⛔ \"Docker\" not found, Installing..."
    sudo bash ./scripts/docker/docker_setup.sh
    echo
fi

SCRIPT_DIR="$( cd "$( dirname "$(readlink -f "$0")" )" && pwd )"
CONFIG_ROOT="/mnt/configs"
DRIVE_ROOT="/mnt/drive1"

echo "→ Creating required directories"

MEDIA_DIRS=(
    "$CONFIG_ROOT/homeassistant"
)

for DIRECTORY in ${MEDIA_DIRS[*]}
do
    mkdir -p $DIRECTORY
    echo "✔ $DIRECTORY"
done
echo

# Write .env file for docker compose
echo "TZ=Asia/Kolkata
ROOT=$DRIVE_ROOT
CONFIG=$CONFIG_ROOT
PUID=$(id -u ritik)
PGID=$(id -g ritik)
" | tee $SCRIPT_DIR/.env > /dev/null

echo "→ Removing existing containers"
echo
docker compose -f $SCRIPT_DIR/compose.yml rm -s -f
echo
echo "→ Deploying new containers"
echo
docker compose -f $SCRIPT_DIR/compose.yml up -d
echo
echo "✔ HomeAssistant deployed successfully."


