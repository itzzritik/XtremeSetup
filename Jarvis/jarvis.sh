#!/bin/bash -e

clear

JarvisLocation="$HOME/.jarvis"
RepoUrl="https://github.com/itzzritik/XtremeSetup.git"

rm -rf "$JarvisLocation"
mkdir -p "$JarvisLocation"

git clone "$RepoUrl" "$JarvisLocation/XtremeSetup" || { echo "✕ Unable to clone the repository"; exit 1; }
bash "$JarvisLocation/XtremeSetup/Jarvis/scripts/index.sh" || { echo "✕ Script execution failed"; exit 1; }

echo "● Cleaning up downloaded scripts"
rm -rf "$JarvisLocation"
echo
echo "✔ Jarvis is ready"
printf '\n+%131s+\n\n' | tr ' ' '-'