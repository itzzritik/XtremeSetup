#!/bin/bash -e

# Check super user permission
if [ $(id -u) -eq 0 ]; then
   echo "⛔ This script needs to run WITHOUT superuser permission"
   exit 1
fi

# Install NVM if not already
if [ -s "$HOME/.nvm/nvm.sh" ]; then
    echo "NVM is already installed."
else
    echo "Installing NVM..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
    source ~/.bashrc
fi

# Install NODE if not already
if which node &> /dev/null; then
    echo "Node is already installed."
else
    echo "Installing Node LTS version..."
    nvm install --lts
    nvm use --lts
fi