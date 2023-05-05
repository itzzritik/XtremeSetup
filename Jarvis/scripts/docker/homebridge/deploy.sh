#!/bin/bash -e

# Check super user permission
if [ $(id -u) -eq 0 ];
then
    echo ⛔ This script needs to run WITHOUT superuser permission!
    exit 1
fi

printf '⚪ Deploying \e]8;;https://homebridge.io\e\\Homebridge\e]8;;\e\\ in Docker\n'
echo

# Install docker if not installed already
if ! [[ $(which docker) && $(docker --version) ]];
then
    echo "⛔ \"Docker\" not found, Installing..."
    sudo bash ./scripts/docker/docker_setup.sh
    echo
fi

SCRIPT_DIR=$(realpath "$(dirname "${BASH_SOURCE[0]}")")
DRIVE_ROOT="/media/drive1"

echo "→ Creating required directories"
echo

MEDIA_DIRS=(
    "$DRIVE_ROOT/.config/homebridge"
)

for DIRECTORY in ${MEDIA_DIRS[*]}
do
    mkdir -p $DIRECTORY
    echo "✔ $DIRECTORY"
done
echo

# Write .env file for docker compose
echo "ROOT=$DRIVE_ROOT" | tee .env > /dev/null

echo "→ Removing existing containers"
echo
docker compose -f $SCRIPT_DIR/compose.yml rm -s -f
echo
echo "→ Deploying new containers"
echo
docker compose -f $SCRIPT_DIR/compose.yml up -d
echo
echo "✔ Homebridge deployed successfully."

