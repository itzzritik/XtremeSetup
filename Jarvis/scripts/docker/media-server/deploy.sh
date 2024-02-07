#!/bin/bash -e

# Check super user permission
if [ $(id -u) -ne 0 ]; then
  echo ⛔ This script needs to run WITH superuser permission!
  exit 1
fi

echo '⚪ Setting up a Media Server using Docker'
echo

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
DRIVE_ROOT="/mnt/drive1"

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
    "$DRIVE_ROOT/.config/qbittorrent"
    "$DRIVE_ROOT/.config/jackett"
    "$DRIVE_ROOT/.config/sonarr"
    "$DRIVE_ROOT/.config/radarr"
    "$DRIVE_ROOT/.config/bazarr"
    "$DRIVE_ROOT/.config/jellyfin"

    "$DRIVE_ROOT/Downloads"
    "$DRIVE_ROOT/Downloads/torrent-blackhole"
    "$DRIVE_ROOT/Public/Series"
    "$DRIVE_ROOT/Public/Movies"
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
echo "✔ Media Server installed successfully."


