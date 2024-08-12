#!/bin/bash -e

echo
echo "+-----------------------------------------------------------------------------------------------------------------------------------+"
echo
printf '⚪ Deploying \e]8;;https://www.home-assistant.io\e\\HomeAssistant\e]8;;\e\\ in Docker\n'
echo

[ $(id -u) -eq 0 ] && echo "⛔ This script needs to run WITHOUT superuser permission" && exit 1

if ! [[ $(which docker) && $(docker --version) ]]; then
  echo "⛔ \"Docker and Docker Compose\" not found, Install them first!" && exit 1
fi

CREATE_DIRS=("$JARVIS_CONFIG_ROOT/homeassistant")
for DIR in ${CREATE_DIRS[*]}; do mkdir -p "$DIR"; done

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"

echo "→ Removing existing containers"
echo
docker compose -f $SCRIPT_DIR/compose.yml rm -s -f
echo
echo "→ Deploying new containers"
echo
docker compose -f $SCRIPT_DIR/compose.yml up -d
echo
echo "✔ HomeAssistant deployed successfully"
