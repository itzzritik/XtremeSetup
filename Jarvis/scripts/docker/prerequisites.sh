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

REQUIRED_VARS=(
  "JARVIS_DRIVE_ROOT"
  "JARVIS_CONFIG_ROOT"
  "JARVIS_TZ"
  "JARVIS_PUID"
  "JARVIS_PGID"
  "JARVIS_ADMIN_NAME"
  "JARVIS_ADMIN_EMAIL"
  "JARVIS_ADMIN_PASSWORD"
  "JARVIS_HOSTNAME"
  "JARVIS_EMAIL"
  "JARVIS_CF_DNS_API_TOKEN"
  "JARVIS_CF_TUNNEL_TOKEN"
)
for VAR in "${REQUIRED_VARS[@]}"; do [ -z "${!VAR}" ] && echo "✕ Env variable \"$VAR\" not set!" && exit 1; done

echo "✔ Disabling systemd-resolved service to avoid port conflicts"
systemctl is-active --quiet systemd-resolved.service && sudo systemctl stop systemd-resolved && sudo systemctl disable systemd-resolved.service

echo "✔ Ensured nameservers are set in /etc/resolv.conf"
grep -q "nameserver 8.8.8.8" /etc/resolv.conf || echo -e "nameserver 8.8.8.8\nnameserver 1.1.1.1" | sudo tee -a /etc/resolv.conf

echo "✔ Removing unused docker containers"
docker rm $(docker ps -aq) >/dev/null 2>&1

echo "✔ Removing unused docker networks"
docker network prune -f >/dev/null 2>&1

echo "✔ Creating docker network → $JARVIS_PROXY_DOCKER_NETWORK"
docker network create --driver bridge "$JARVIS_PROXY_DOCKER_NETWORK" >/dev/null 2>&1

echo "✔ Creating docker network → ${JARVIS_CERT_RESOLVER}"
docker volume create "${JARVIS_CERT_RESOLVER}" >/dev/null 2>&1