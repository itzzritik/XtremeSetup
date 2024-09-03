#!/bin/bash -e

NAME=Caddy
NAME_LOWER="${NAME,,}"
URL=https://caddyserver.com

printf '\n+%131s+\n\n' | tr ' ' '-'
printf '⚪ Deploying \e]8;;%s\a%s\e]8;;\a in Docker\n' "$URL" "$NAME"
echo

[ $(id -u) -eq 0 ] && echo "⛔ This script needs to run WITHOUT superuser permission" && exit 1

[ -z "$(command -v docker)" ] && echo "⛔ Docker not found, Install it first!" && exit 1

if docker ps --filter "name=$NAME_LOWER" --filter "status=running" --format "{{.Names}}" | grep -q "^$NAME_LOWER$"; then
    echo "✔ Container already up and running" && exit 0
fi

CREATE_DIRS=("$JARVIS_CONFIG_ROOT/$NAME_LOWER")
for DIR in ${CREATE_DIRS[*]}; do mkdir -p "$DIR"; done

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"

echo "→ Setting config file to $JARVIS_CONFIG_ROOT/$NAME_LOWER"
cp -f "$SCRIPT_DIR/Caddyfile" "$JARVIS_CONFIG_ROOT/$NAME_LOWER/Caddyfile"

echo "→ Removing existing containers"
echo
docker compose -f $SCRIPT_DIR/compose.yml rm -s -f
echo
echo "→ Deploying new containers"
echo
docker compose -f $SCRIPT_DIR/compose.yml up -d
echo
echo "✔ $NAME deployed successfully"
