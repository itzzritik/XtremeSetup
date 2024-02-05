#!/bin/bash -e

# Check super user permission
if [ $(id -u) -eq 0 ]; then
   echo "⛔ This script needs to run WITHOUT superuser permission"
   exit 1
fi

# Check if NVM is installed
if ! command -v nvm &> /dev/null
then
    echo "Installing NVM..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | zsh
    echo -e '\nexport NVM_DIR="$HOME/.nvm"\n[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"\n[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >> ~/.zshrc
    source ~/.zshrc
else
    echo "NVM is already installed."
fi

nvm install --lts
nvm use --lts

# Check if Node LTS is installed
if ! command -v node &> /dev/null
then
    echo "Installing Node LTS version..."
    nvm install --lts
    nvm use --lts
else
    echo "Node is already installed."
fi