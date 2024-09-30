#!/bin/bash -e

clear

JARVIS_SETUP="$HOME/.jarvis/setup"
SCRIPT_REPO="https://github.com/itzzritik/XtremeSetup.git"

rm -rf "$JARVIS_SETUP"
mkdir -p "$JARVIS_SETUP"

git clone "$SCRIPT_REPO" "$JARVIS_SETUP/XtremeSetup" || { echo "✕ Unable to clone the SCRIPT_sitory"; exit 1; }
bash "$JARVIS_SETUP/XtremeSetup/Jarvis/scripts/index.sh" || { echo "✕ Script execution failed"; exit 1; }

echo "● Cleaning up downloaded scripts"
rm -rf "$JARVIS_SETUP"
echo
echo "✔ Jarvis is ready"
printf '\n+%131s+\n\n' | tr ' ' '-'