#!/bin/bash -e

printf '\n+%131s+\n\n' | tr ' ' '-'
echo -e "⚪ Setup 1Password\n"

EMAIL="ritik.space@gmail.com"

if ! command -v op &> /dev/null; then
    echo -e "→ Installing 1Password cli\n"

    curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
    sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg

    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main" |
    sudo tee /etc/apt/sources.list.d/1password.list

    sudo mkdir -p /etc/debsig/policies/AC2D62742012EA22/
    curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol | \
    sudo tee /etc/debsig/policies/AC2D62742012EA22/1password.pol
    sudo mkdir -p /usr/share/debsig/keyrings/AC2D62742012EA22
    curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
    sudo gpg --dearmor --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg

    sudo apt update && sudo apt install 1password-cli

    [ ! command -v op &> /dev/null ] && echo -e "\n⛔ 1Password cli installation failed\n" && exit 1;
    echo -e "\n✔ 1Password cli installed successfully\n"
fi

if ! $(op account list &> /dev/null); then
echo "→ Adding account $EMAIL"
read -p "→ Enter secret key: " SECRET_KEY
echo

op account add --address my.1password.com --email "$EMAIL" --secret-key "$SECRET_KEY" --shorthand "$USER"

[ $(op account list &> /dev/null) ] && echo "✔ 1Password already set with account: $(op account list --format=json | jq -r '.[0].email')" && exit 1;

echo "→ Authenticate 1Password cli"
echo "→ Email set to: $EMAIL"
read -p "→ Enter secret key for: " SECRET_KEY
echo

eval $(op account add --address my.1password.com --email "$EMAIL" --secret-key "$SECRET_KEY" --shorthand "$USER" --signin)

[ ! $(op account list &> /dev/null) ] && echo -e "\n⛔ 1Password cli setup failed\n" && exit 1;



[ $(op whoami &> /dev/null) ] && echo "✔ 1Password already signed in as: $(op whoami --format=json | jq -r '.email')" && exit 0

echo "→ Authenticate 1Password cli"
echo "→ Email set to: $EMAIL"
read -p "→ Enter secret key for: " SECRET_KEY
echo
op account add --address my.1password.com --email "$EMAIL" --secret-key "$SECRET_KEY" --shorthand "$USER"
echo "✔ Account added successfully\n"
echo "→ Signing in to: $EMAIL"
eval $(op signin)

[ ! $(op whoami &> /dev/null) ] && echo -e "\n⛔ 1Password cli setup failed\n" && exit 1;

echo "✔ Successfully signed in to 1Password"
