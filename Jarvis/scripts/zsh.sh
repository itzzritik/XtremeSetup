#!/bin/bash -e

# Check super user permission
if [ $(id -u) -eq 0 ]; then
   echo "⛔ This script needs to run WITHOUT superuser permission"
   exit 1
fi

echo "⚪ Setting up zsh and oh-my-zsh"
echo

if command -v zsh &> /dev/null; then
    echo "Zsh is already installed."
else
    echo "Installing ZSH..."
    apt install zsh -y
    echo "zsh installed successfully"
fi

if [ -d "$HOME/.oh-my-zsh" ]; then
    echo "Oh My Zsh is already installed."
else
    echo "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://install.ohmyz.sh/)"
    echo "Oh My Zsh installed successfully"
fi