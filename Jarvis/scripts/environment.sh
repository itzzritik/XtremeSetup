#!/bin/bash

echo -e '⚪ Setting jarvis environment\n'

ENV_FILE="/etc/jarvis/.env"
REQUIRED_VARS=("JARVIS_USERNAME" "JARVIS_PASSWORD" "JARVIS_CF_DNS_API_TOKEN" "JARVIS_CF_TUNNEL_TOKEN")

export JARVIS_GOOGLE_DNS="8.8.8.8;8.8.4.4"
export JARVIS_STATIC_IP="192.168.68.255"
export JARVIS_DOMAIN="myjarvis.in"
export JARVIS_HOSTNAME="jarvis"
export JARVIS_TZ="Asia/Kolkata"
export JARVIS_PUID=$(id -u $USER)
export JARVIS_PGID=$(id -g $USER)
export JARVIS_USER_NAME="Jarvis"
export JARVIS_USER_EMAIL="ritik.jarvis@gmail.com"

export JARVIS_DRIVE_ROOT="/mnt/drive1"
export JARVIS_CONFIG_ROOT="$JARVIS_DRIVE_ROOT/.configs"

prompt_and_update_file() {
    local var_name=$1 value

    while true; do
        read -p "→ Enter value for $var_name: " value
        if [ -n "$value" ]; then
            echo "$var_name=\"$value\"" | sudo tee -a "$ENV_FILE" > /dev/null
            export "$var_name=${value//\"/}"
            break
        fi
        echo -e "✕ Error: $var_name cannot be empty. Please enter a value.\n"
    done
}

[ -f "$ENV_FILE" ] || sudo touch "$ENV_FILE"

while IFS='=' read -r key value; do
    [ "$key" ] && export "$key=${value//\"/}"
done < "$ENV_FILE"

for var in "${REQUIRED_VARS[@]}"; do
    [ -z "${!var}" ] && prompt_and_update_file "$var"
done

echo "✔ Environment set successfully"