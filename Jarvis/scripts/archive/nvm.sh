#!/bin/bash -e

printf '\n+%131s+\n\n' | tr ' ' '-'
echo "⚪ Setting up node environment"
echo

# Check super user permission
if [ $(id -u) -eq 0 ]; then
    echo "⛔ This script needs to run WITHOUT superuser permission"
    exit 1
fi

currentUser=$(who am i | awk '{print $1}')
echo "Executing as user: $currentUser"

# Install NVM if not already
if [ -s "$HOME/.nvm/nvm.sh" ]; then
    echo "✔ NVM is already installed"
else
    echo "Installing NVM..."
    su - $currentUser -c "$(curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash)"
    source ~/.nvm/nvm.sh
    echo
    echo "✔ NVM installed successfully"
fi

# Install NODE if not already
if which node &> /dev/null; then
    echo "✔ Node is already installed"
else
    echo "Installing Node LTS version..."
    su - $currentUser -c "
        source ~/.nvm/nvm.sh
        nvm install --lts
        nvm alias default lts/*
        nvm use --lts
    "
    echo "✔ Node LTS version installed successfully"
fi