#!/bin/bash
set -euo pipefail

STORAGE_IP="192.168.68.245"
SMB_USER="root"

command -v doppler >/dev/null || brew install dopplerhq/cli/doppler

SMB_PASS=$(doppler secrets get JARVIS_ADMIN_PASSWORD --project jarvis --config prd --plain) || {
    echo "✕ Run: doppler login"; exit 1
}

osascript << EOF
try
    mount volume "smb://${SMB_USER}:${SMB_PASS}@${STORAGE_IP}/media"
end try
try
    mount volume "smb://${SMB_USER}:${SMB_PASS}@${STORAGE_IP}/ssd"
end try
EOF

echo "✔ Shares mounted in Finder"
