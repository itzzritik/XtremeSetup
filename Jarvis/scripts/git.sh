#!/bin/bash

printf '\n+%131s+\n\n' | tr ' ' '-'
echo "⚪ Setting up git environment"
echo

USER_NAME="Ritik Srivastava"
USER_EMAIL="ritik.space@gmail.com"
CURRENT_USER_NAME=$(git config --global user.name)
CURRENT_USER_EMAIL=$(git config --global user.email)
KEY_NAME="id_ed25519"
KEY_PATH="$HOME/.ssh/$KEY_NAME"

if [ "$CURRENT_USER_NAME" != "$USER_NAME" ]; then
    echo "✔ Setting Git user name to $USER_NAME"
    git config --global user.name "$USER_NAME"
else
    echo "✔ Username already set to $CURRENT_USER_NAME"
fi

if [ "$CURRENT_USER_EMAIL" != "$USER_EMAIL" ]; then
    echo "✔ Setting Git user email to $USER_EMAIL"
    git config --global user.email "$USER_EMAIL"
else
    echo "✔ Email already set to $CURRENT_USER_EMAIL"
fi
echo

if [ -f "$KEY_PATH" ] && [ -f "$KEY_PATH.pub" ]; then
    echo "→ SSH keys already exist at \"$KEY_PATH\""
else
    echo "→ Generating new SSH key at \"$KEY_PATH\""
    ssh-keygen -t ed25519 -C "$USER_EMAIL" -f "$KEY_PATH" -N ""
fi
echo
echo "→ Adding the key to ssh-agent"
eval "$(ssh-agent -s)"
ssh-add "$KEY_PATH"
echo
echo "→ Please add below auth and signing key to your GitHub account:"
cat "$KEY_PATH.pub"
echo
echo "→ Configuring git to use the SSH key for signing commits"
git config --global gpg.format ssh
git config --global user.signingkey "$KEY_PATH.pub"
git config --global commit.gpgSign true

echo "✔ Git environment setup successfully"