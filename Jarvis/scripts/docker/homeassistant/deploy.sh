#!/bin/bash -e

NAME="HomeAssistant"
NAME_LOWER="${NAME,,}"

echo
echo "+-----------------------------------------------------------------------------------------------------------------------------------+"
echo
printf '⚪ Deploying \e]8;;https://www.home-assistant.io\e\\HomeAssistant\e]8;;\e\\ in Docker\n'
echo

[ $(id -u) -eq 0 ] && echo "⛔ This script needs to run WITHOUT superuser permission" && exit 1

[ -z "$(command -v docker)" ] && echo "⛔ Docker not found, Install it first!" && exit 1

CREATE_DIRS=("$JARVIS_CONFIG_ROOT/$NAME_LOWER")
for DIR in ${CREATE_DIRS[*]}; do mkdir -p "$DIR"; done

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"

if docker ps --filter "name=$NAME_LOWER" --filter "status=running" --format "{{.Names}}" | grep -q "^$NAME_LOWER$"; then
    echo "✔ Container already up and running" && exit 0
fi

echo "→ Removing existing containers"
echo
docker compose -f $SCRIPT_DIR/compose.yml rm -s -f
echo
echo "→ Deploying new containers"
echo
docker compose -f $SCRIPT_DIR/compose.yml up -d
echo
echo "✔ $NAME deployed successfully"
