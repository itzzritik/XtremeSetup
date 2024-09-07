#!/bin/bash -e

echo
printf '+%131s+\n' | tr ' ' '-'
echo
printf '⚪ Setting up \e]8;;https://www.docker.com\e\\Docker\e]8;;\e\\\n'
echo

[ $(id -u) -eq 0 ] && echo "⛔ This script needs to run WITHOUT superuser permission" && exit 1

if ! [[ $(docker --version) ]]; then
  sudo apt install ca-certificates gnupg
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

  echo
  echo "✔ Docker installed successfully"
else
  echo "✔ Docker is already installed"
fi

REQUIRED_VARS=(
  "JARVIS_DRIVE_ROOT"
  "JARVIS_CONFIG_ROOT"
  "JARVIS_TZ"
  "JARVIS_PUID"
  "JARVIS_PGID"
  "JARVIS_USERNAME"
  "JARVIS_PASSWORD"
  "JARVIS_HOSTNAME"
  "JARVIS_USER_EMAIL"
  "JARVIS_CLOUDFLARED_TOKEN"
)

for VAR in "${REQUIRED_VARS[@]}"; do [ -z "${!VAR}" ] && echo "⛔ Env variable \"$VAR\" not set!" && exit 1; done

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"

echo "✔ Disabling systemd-resolved service to avoid port conflicts"
sudo systemctl disable systemd-resolved.service
sudo systemctl stop systemd-resolved

echo "✔ Removing unused docker containers"
docker rm $(docker ps -a -q) >/dev/null 2>&1

echo "✔ Removing unused docker networks"
docker network prune -f >/dev/null 2>&1

for dir in "$SCRIPT_DIR"/*/; do
  [ -f "$dir/deploy.sh" ] && bash "$dir/deploy.sh"
done

bash "$SCRIPT_DIR/post-scripts.sh"
