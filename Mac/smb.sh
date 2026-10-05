#!/bin/bash
set -euo pipefail

HOST=192.168.68.245
USER_NAME=root
SHARES=(ssd media)
DIR="$(cd "$(dirname "$0")" && pwd)"

command -v doppler >/dev/null || brew install doppler
pass=$(doppler secrets get JARVIS_ADMIN_PASSWORD --project jarvis --config prd --scope "$DIR" --plain) || { echo "✕ Run: doppler login --scope $DIR"; exit 1; }
pass=${pass//\\/\\\\}
pass=${pass//\"/\\\"}

for share in "${SHARES[@]}"; do
    osascript >/dev/null <<APPLESCRIPT
mount volume "smb://$HOST/$share" as user name "$USER_NAME" with password "$pass"
APPLESCRIPT
    echo "✔ /Volumes/$share"
done
