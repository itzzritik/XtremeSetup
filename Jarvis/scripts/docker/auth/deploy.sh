#!/bin/bash -e

NAME=Auth
CONTAINER_NAME="${NAME,,}"
URL="https://www.authelia.com"
export JARVIS_CONTAINER_NAME=$CONTAINER_NAME

printf '\n+%131s+\n\n' | tr ' ' '-'
printf '● Deploying \e]8;;%s\a%s\e]8;;\a in Docker\n\n' "$URL" "$NAME"

[ $(id -u) -eq 0 ] && echo "✕ This script needs to run WITHOUT superuser permission" && exit 1

[ -z "$(command -v docker)" ] && echo "✕ Docker not found, Install it first!" && exit 1

if docker ps --filter "name=$CONTAINER_NAME" --filter "status=running" --format "{{.Names}}" | grep -q "^$CONTAINER_NAME$"; then
    echo "✔ Container already up and running" && exit 0
fi

REQUIRED_VARS=(
    "JARVIS_AUTH_JWT_SECRET"
    "JARVIS_AUTH_SESSION_KEY"
    "JARVIS_AUTH_STORAGE_KEY"
    "JARVIS_AUTH_GOOGLE_APP_PASSWORD"
    "JARVIS_AUTH_REDIRECT_URL"
    "JARVIS_GITHUB_CLIENT_ID"
    "JARVIS_GITHUB_CLIENT_SECRET"
)
for VAR in "${REQUIRED_VARS[@]}"; do [ -z "${!VAR}" ] && echo "✕ Env variable \"$VAR\" not set!" && exit 1; done

CONFIG_PATH="$JARVIS_CONFIG_ROOT/$CONTAINER_NAME/config"
mkdir -p "$CONFIG_PATH"

cat >"$CONFIG_PATH/configuration.yml" <<EOL
server:
  address: tcp://:9091

log:
  level: debug

totp:
  issuer: $JARVIS_DOMAIN

identity_validation:
  reset_password:
    jwt_secret: $JARVIS_AUTH_JWT_SECRET

authentication_backend:
  file:
    path: /config/users_database.yml

access_control:
  default_policy: two_factor
  rules:
    - domain: homarr.$JARVIS_DOMAIN
      policy: bypass
    - domain: dashdot.$JARVIS_DOMAIN
      policy: bypass
    - domain: alist.$JARVIS_DOMAIN
      policy: bypass
    - domain: traefik.$JARVIS_DOMAIN
      policy: one_factor

session:
  secret: $JARVIS_AUTH_SESSION_KEY
  cookies:
    - name: $JARVIS_HOSTNAME
      domain: $JARVIS_DOMAIN
      authelia_url: https://$CONTAINER_NAME.$JARVIS_DOMAIN
      expiration: 6 hour
      inactivity: 5 minutes

regulation:
  max_retries: 5
  find_time: 2 minutes
  ban_time: 5 minutes

storage:
  encryption_key: $JARVIS_AUTH_STORAGE_KEY
  local:
    path: /config/db.sqlite3

notifier:
  smtp:
    username: $JARVIS_EMAIL
    password: $JARVIS_AUTH_GOOGLE_APP_PASSWORD
    address: smtp://smtp.gmail.com:587
    sender: hi@$JARVIS_DOMAIN
EOL

HASHED_PASSWORD=$(echo -n "$JARVIS_ADMIN_PASSWORD" | argon2 "$(openssl rand -hex 16)" -id -t 3 -m 12 -p 1 | awk '/Encoded:/ {print $2}')
DB_PATH="$CONFIG_PATH/users_database.yml"
{ [ -s "$DB_PATH" ] || cat >"$DB_PATH"; } <<EOL
users:
  $(echo "$JARVIS_ADMIN_NAME" | awk '{print tolower($1)}'):
    disabled: false
    displayname: $JARVIS_ADMIN_NAME
    password: $HASHED_PASSWORD
    email: $JARVIS_ADMIN_EMAIL
    groups:
      - admins
      - dev
EOL

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
