#!/bin/bash -e

clear

PROXMOX_SETUP="$HOME/.proxmox/setup"
SCRIPT_REPO="https://github.com/itzzritik/XtremeSetup.git"

rm -rf "$PROXMOX_SETUP"
mkdir -p "$PROXMOX_SETUP"

git clone "$SCRIPT_REPO" "$PROXMOX_SETUP/XtremeSetup" || { echo "✕ Unable to clone the SCRIPT_sitory"; exit 1; }
bash "$PROXMOX_SETUP/XtremeSetup/ProxmoxAnsible/scripts/index.sh" || { echo "✕ Script execution failed"; exit 1; }

echo "● Cleaning up downloaded scripts"
rm -rf "$PROXMOX_SETUP"
echo
echo "✔ Jarvis is ready"
printf '\n+%131s+\n\n' | tr ' ' '-'