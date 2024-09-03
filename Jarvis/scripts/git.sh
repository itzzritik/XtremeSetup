#!/bin/bash

printf '\n+%131s+\n\n' | tr ' ' '-'
echo "⚪ Setting up git environment"
echo

REQUIRED_VARS=(
  "JARVIS_USER_NAME"
  "JARVIS_USER_EMAIL"
)
for VAR in "${REQUIRED_VARS[@]}"; do [ -z "${!VAR}" ] && echo "⛔ Env variable \"$VAR\" not set!" && exit 1; done

KEY_PATH="$HOME/.ssh/id_ed25519"

git config --global user.name "$JARVIS_USER_NAME"
git config --global user.email "$JARVIS_USER_EMAIL"

echo "✔ Git user name: $(git config --global user.name)"
echo "✔ Git user email: $(git config --global user.email)"

if [ -f "$KEY_PATH" ] && [ -f "$KEY_PATH.pub" ]; then
    echo "✔ SSH keys already exist at \"$KEY_PATH.pub\""
else
    echo "→ Generating new SSH key at \"$KEY_PATH\""
    ssh-keygen -t ed25519 -C "$JARVIS_USER_EMAIL" -f "$KEY_PATH" -N ""
    eval "$(ssh-agent -s)"
    ssh-add "$KEY_PATH"
    echo -e "\n→ Please add the following SSH key to your GitHub account:"
    cat "$KEY_PATH.pub"
fi

echo "✔ Git environment setup successfully"