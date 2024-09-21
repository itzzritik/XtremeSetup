#!/bin/bash -e

[ $(id -u) -eq 0 ] && echo "✕ This script needs to run WITHOUT superuser permission" && exit 1

if ! [[ $(docker --version) ]]; then
  echo -e "→ Installing Docker\n"
  sudo apt install ca-certificates gnupg -y
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --yes --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg
  echo \
    "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    "$(lsb_release -cs)" stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

  sudo apt update
  sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

  newgrp docker
  sudo usermod -aG docker $USER
  echo -e "\n✔ Docker installed successfully"
fi

if ! command -v argon2 >/dev/null 2>&1; then
  echo -e "→ Installing Argon2 for password hashing\n"
  sudo apt install -y argon2
  echo -e "\n✔ Argon2 installed successfully"
fi

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"

echo "✔ Removing docker apps log files"
find "$SCRIPT_DIR" -type f -name 'debug.log' -delete

echo "✔ Disabling systemd-resolved service to avoid port conflicts"
systemctl is-active --quiet systemd-resolved.service && sudo systemctl stop systemd-resolved && sudo systemctl disable systemd-resolved.service

echo "✔ Ensuring nameservers are set in /etc/resolv.conf"
grep -q "nameserver 8.8.8.8" /etc/resolv.conf || echo -e "nameserver 8.8.8.8\nnameserver 1.1.1.1" | sudo tee -a /etc/resolv.conf

echo "✔ Removing unused docker containers"
docker rm $(docker ps -aq) >/dev/null 2>&1

echo "✔ Removing unused docker networks"
docker network prune -f >/dev/null 2>&1

echo "✔ Creating docker network → $JARVIS_PROXY_DOCKER_NETWORK"
docker network create --driver bridge "$JARVIS_PROXY_DOCKER_NETWORK" >/dev/null 2>&1

printf '\n+%131s+\n\n' | tr ' ' '-'