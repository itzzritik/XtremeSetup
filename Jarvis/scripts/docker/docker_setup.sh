#!/bin/bash -e

echo
echo "+-----------------------------------------------------------------------------------------------------------------------------------+"
echo
printf '⚪ Setting up \e]8;;https://www.docker.com\e\\Docker\e]8;;\e\\\n'
echo

# Check super user permission
if [ $(id -u) -ne 0 ]; then
  echo ⛔ This script needs to run WITH superuser permission!
  exit 1
fi

# Check if docker is already installed
if [[ $(which docker) && $(docker --version) ]];
then
  echo "✔ Docker is already installed!"
  exit 0
fi

# Install dependencies
sudo apt install ca-certificates gnupg

# Add Docker’s official GPG key
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --yes --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Set up the Docker’s repository
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(lsb_release -cs)" stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

newgrp docker
sudo usermod -aG docker $USER

echo
echo "✔ Docker installed successfully"