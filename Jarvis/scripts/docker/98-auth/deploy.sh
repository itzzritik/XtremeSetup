#!/bin/bash -e

NAME=Auth
CONTAINER_NAME="${NAME,,}"
URL="https://oauth2-proxy.github.io/oauth2-proxy"
export JARVIS_CONTAINER_NAME=$CONTAINER_NAME

printf '\n+%131s+\n\n' | tr ' ' '-'
printf '⚪ Deploying \e]8;;%s\a%s\e]8;;\a in Docker\n' "$URL" "$NAME"
echo

[ $(id -u) -eq 0 ] && echo "⛔ This script needs to run WITHOUT superuser permission" && exit 1

[ -z "$(command -v docker)" ] && echo "⛔ Docker not found, Install it first!" && exit 1

if docker ps --filter "name=$CONTAINER_NAME" --filter "status=running" --format "{{.Names}}" | grep -q "^$CONTAINER_NAME$"; then
    echo "✔ Container already up and running" && exit 0
fi

REQUIRED_VARS=(
    "JARVIS_GITHUB_CLIENT_ID"
    "JARVIS_GITHUB_CLIENT_SECRET"
    "JARVIS_AUTH_REDIRECT_URL"
)
for VAR in "${REQUIRED_VARS[@]}"; do [ -z "${!VAR}" ] && echo "⛔ Env variable \"$VAR\" not set!" && exit 1; done

CREATE_DIRS=("$JARVIS_CONFIG_ROOT/$CONTAINER_NAME")
for DIR in ${CREATE_DIRS[*]}; do mkdir -p "$DIR"; done

sudo tee "$JARVIS_CONFIG_ROOT/$CONTAINER_NAME/oauth2-proxy.cfg" >/dev/null <<EOL
provider = "github"
client_id = "$JARVIS_GITHUB_CLIENT_ID"
client_secret = "$JARVIS_GITHUB_CLIENT_SECRET"
redirect_url = "$JARVIS_AUTH_REDIRECT_URL"
email_domains = ["ritik.space@gmail.com", "hi@ritik.me"]
EOL
export JARVIS_COOKIE_SECRET=$(openssl rand -base64 32 | tr -- '+/' '-_')

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"

echo "→ Removing existing containers"
echo
docker compose -f $SCRIPT_DIR/compose.yml rm -s -f
echo
echo "→ Deploying new containers"
echo
docker compose -f $SCRIPT_DIR/compose.yml up -d
echo
echo "✔ $NAME deployed successfully"
