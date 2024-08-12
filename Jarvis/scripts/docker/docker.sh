#!/bin/bash -e

echo
echo "+-----------------------------------------------------------------------------------------------------------------------------------+"
echo
printf '⚪ Setting up \e]8;;https://www.docker.com\e\\Docker\e]8;;\e\\\n'
echo

[ $(id -u) -eq 0 ] && echo "⛔ This script needs to run WITHOUT superuser permission" && exit 1

if ! [[ $(which docker) && $(docker --version) ]]; then
  # Install dependencies
  sudo apt install ca-certificates gnupg

  # Add Docker’s official GPG key
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --yes --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg

  # Set up the Docker’s repository
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
  echo "✔ Docker is already installed!"
fi

REQUIRED_VARS=(
  "JARVIS_DRIVE_ROOT"
  "JARVIS_CONFIG_ROOT"
  "JARVIS_TZ"
  "JARVIS_PUID"
  "JARVIS_PGID"
)

for VAR in "${REQUIRED_VARS[@]}"; do [ -z "${!VAR}" ] && echo "⛔ Env variable \"$VAR\" not set!" && exit 1; done

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"

bash $SCRIPT_DIR/portrainer/deploy.sh
bash $SCRIPT_DIR/homeassistant/deploy.sh
# sudo bash $SCRIPT_DIR/homebridge/deploy.sh
# sudo bash $SCRIPT_DIR/media-server/deploy.sh
# sudo bash $SCRIPT_DIR/pihole/deploy.sh
