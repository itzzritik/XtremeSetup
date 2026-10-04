#!/bin/bash
set -euo pipefail

REPO="https://github.com/itzzritik/XtremeSetup/archive/HEAD.tar.gz"
WORK_DIR="$HOME/.jarvis/setup"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET=${1:?Usage: bash CodingServer/index.sh <oracle|proxmox> [task...]}
shift
ONLY=$(IFS=,; echo "${*:-}")

command -v ansible >/dev/null || brew install ansible
command -v doppler >/dev/null || brew install doppler

if [[ ! -f "$SCRIPT_DIR/main.yml" ]]; then
    trap 'rm -rf "$WORK_DIR"' EXIT
    mkdir -p "$WORK_DIR"
    curl -Ls "$REPO" | tar -xz -C "$WORK_DIR" --strip-components=2 "*/CodingServer"
    SCRIPT_DIR="$WORK_DIR"
fi

cd "$SCRIPT_DIR"
ansible-galaxy collection install -r requirements.yml --upgrade >/dev/null
ansible-playbook main.yml -e "target=$TARGET" -e "only=$ONLY"
