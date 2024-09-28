#!/bin/bash -e

clear

JARVIS_SCRIPTS="$HOME/.jarvis/setup"
SCRIPT_REPO="https://github.com/itzzritik/XtremeSetup.git"

rm -rf "$JARVIS_SCRIPTS"
mkdir -p "$JARVIS_SCRIPTS"

git clone "$SCRIPT_REPO" "$JARVIS_SCRIPTS/XtremeSetup" || { echo "✕ Unable to clone the SCRIPT_sitory"; exit 1; }
bash "$JARVIS_SCRIPTS/XtremeSetup/Jarvis/scripts/index.sh" || { echo "✕ Script execution failed"; exit 1; }

echo "● Cleaning up downloaded scripts"
rm -rf "$JARVIS_SCRIPTS"
echo
echo "✔ Jarvis is ready"
printf '\n+%131s+\n\n' | tr ' ' '-'