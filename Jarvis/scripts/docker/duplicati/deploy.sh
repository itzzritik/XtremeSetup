#!/bin/bash -e

NAME="Duplicati"
NAME_LOWER="${NAME,,}"

echo
echo "+-----------------------------------------------------------------------------------------------------------------------------------+"
echo
printf '⚪ Deploying \e]8;;https://duplicati.com\e\\Duplicati\e]8;;\e\\ in Docker\n'
echo

[ $(id -u) -eq 0 ] && echo "⛔ This script needs to run WITHOUT superuser permission" && exit 1

[ -z "$(command -v docker)" ] && echo "⛔ Docker not found, Install it first!" && exit 1

CREATE_DIRS=("$JARVIS_DRIVE_ROOT/.$NAME_LOWER/configs" "$JARVIS_DRIVE_ROOT/.$NAME_LOWER/backups")
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
