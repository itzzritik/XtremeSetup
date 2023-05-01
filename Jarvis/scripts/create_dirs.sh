#!/bin/bash -e

# Check super user permission
if [ $(id -u) -eq 0 ];
then
  echo "⛔ This script needs to run WITHOUT superuser permission"
  exit 1
fi

echo "⚪ Creating required directories"
echo

JARVIS_DIRS=(
    # Automount Drive
    "/media/drive1"

    # Homebridge
    "/media/drive1/.config/homebridge"

    # Torrent - Transmission & Flood
    "/media/drive1/.config/torrent"
    "/media/drive1/Downloads/Torrent"
    "/media/drive1/Downloads/Torrent/.incomplete"

    # Jellyfin
    "/media/drive1/.config/jellyfin"
    "/media/drive1/Public/Series"
    "/media/drive1/Public/Movies"
)

for DIRECTORY in ${JARVIS_DIRS[*]}
do
    mkdir -p $DIRECTORY
    echo "✅ $DIRECTORY"
done
