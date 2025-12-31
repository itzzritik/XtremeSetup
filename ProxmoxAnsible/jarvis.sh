#!/bin/bash
set -euo pipefail

REPO_URL="https://github.com/itzzritik/XtremeSetup"
TEMP_DIR="$HOME/.jarvis/proxmox_ansible_setup"

cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT INT TERM HUP


check_requirements() {
    for cmd in brew curl tar; do command -v "$cmd" >/dev/null || { echo "Error: $cmd is required."; exit 1; }; done
    command -v ansible >/dev/null || brew install ansible &>/dev/null
}

prepare_workspace() {
    rm -rf "$TEMP_DIR"
    mkdir -p "$TEMP_DIR/XtremeSetup"
    curl -L -s "$REPO_URL/archive/HEAD.tar.gz" | tar -xz -C "$TEMP_DIR/XtremeSetup" --strip-components=1
}

run_playbook() {
    cd "$TEMP_DIR/XtremeSetup/ProxmoxAnsible"
    ansible-playbook main.yml
}

check_requirements
prepare_workspace
run_playbook
