#!/bin/bash -e

echo
echo "+-----------------------------------------------------------------------------------------------------------------------------------+"
echo
echo '⚪ Setting up a Media Server using Docker'
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


