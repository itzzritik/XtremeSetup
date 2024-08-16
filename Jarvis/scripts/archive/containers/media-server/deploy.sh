#!/bin/bash -e

printf '\n+%131s+\n\n' | tr ' ' '-'
echo '⚪ Setting up a Media Server using Docker'
echo

[ $(id -u) -eq 0 ] && echo "⛔ This script needs to run WITHOUT superuser permission" && exit 1

[ -z "$(command -v docker)" ] && echo "⛔ Docker not found, Install it first!" && exit 1

SERVICES=(
    "qBittorrent https://www.qbittorrent.org"
    "Jackett https://github.com/Jackett/Jackett"
    "Sonarr https://sonarr.tv"
    "Radarr https://radarr.video"
    "Bazarr https://www.bazarr.media"
    "Jellyfin https://jellyfin.org"
)
SCRIPT_DIR="$( cd "$( dirname "$(readlink -f "$0")" )" && pwd )"
JARVIS_CONFIG_ROOT="/mnt/configs"
JARVIS_DRIVE_ROOT="/mnt/drive1"

echo ' → Deploying services:'

for SERVICE in "${SERVICES[@]}"
do
    set -- $SERVICE
    printf "   → \e]8;;$2\e\\$1 ($2)\e]8;;\e\ \n"
done
echo

echo "→ Creating required directories"
echo

MEDIA_DIRS=(
    # Create config dirs
    "$JARVIS_DRIVE_ROOT/.config/qbittorrent"
    "$JARVIS_DRIVE_ROOT/.config/jackett"
    "$JARVIS_DRIVE_ROOT/.config/sonarr"
    "$JARVIS_DRIVE_ROOT/.config/radarr"
    "$JARVIS_DRIVE_ROOT/.config/bazarr"
    "$JARVIS_DRIVE_ROOT/.config/jellyfin"

    "$JARVIS_DRIVE_ROOT/Downloads"
    "$JARVIS_DRIVE_ROOT/Downloads/torrent-blackhole"
    "$JARVIS_DRIVE_ROOT/Public/Series"
    "$JARVIS_DRIVE_ROOT/Public/Movies"
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
echo "✔ Media Server installed successfully"


