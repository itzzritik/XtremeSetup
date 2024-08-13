#!/bin/bash -e

echo
echo "+-----------------------------------------------------------------------------------------------------------------------------------+"
echo
printf '⚪ Deploying \e]8;;https://pi-hole.net\e\\PiHole\e]8;;\e\\ in Docker\n'
echo

[ $(id -u) -eq 0 ] && echo "⛔ This script needs to run WITHOUT superuser permission" && exit 1

[ -z "$(command -v docker)" ] && echo "⛔ Docker not found, Install it first!" && exit 1

SCRIPT_DIR="$( cd "$( dirname "$(readlink -f "$0")" )" && pwd )"
JARVIS_DRIVE_ROOT="/mnt/drive1"

echo "→ Creating required directories"
echo

MEDIA_DIRS=(
    "$JARVIS_DRIVE_ROOT/.config/pihole"
)

for DIRECTORY in ${MEDIA_DIRS[*]}
do
    mkdir -p $DIRECTORY
    echo "✔ $DIRECTORY"
done
echo

# Write .env file for docker compose
echo "TZ=Asia/Kolkata
ROOT=$JARVIS_DRIVE_ROOT
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
echo "✔ PiHole deployed successfully"


