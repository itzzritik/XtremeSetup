#!/bin/bash -e

echo
echo "+-----------------------------------------------------------------------------------------------------------------------------------+"
echo
printf '⚪ Deploying \e]8;;https://www.portainer.io\e\\Portainer\e]8;;\e\\ in Docker\n'
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

echo "→ Removing existing containers"
echo
docker compose -f $SCRIPT_DIR/compose.yml rm -s -f
echo
echo "→ Deploying new containers"
echo
docker compose -f $SCRIPT_DIR/compose.yml up -d
echo
echo "✔ Portainer deployed successfully"


