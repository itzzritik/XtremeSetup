#!/bin/bash
set -euo pipefail

REPO="https://github.com/itzzritik/XtremeSetup/archive/HEAD.tar.gz"
WORK_DIR="$HOME/.jarvis/setup"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

command -v ansible >/dev/null || brew install ansible

if [[ -f "$SCRIPT_DIR/main.yml" ]]; then
    cd "$SCRIPT_DIR"
    ansible-playbook main.yml
else
    trap 'rm -rf "$WORK_DIR"' EXIT
    mkdir -p "$WORK_DIR"
    curl -Ls "$REPO" | tar -xz -C "$WORK_DIR" --strip-components=2 "*/ProxmoxAnsible"
    cd "$WORK_DIR"
    ansible-playbook main.yml
fi
