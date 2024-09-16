printf '\n+%131s+\n\n' | tr ' ' '-'
echo -e "● Pre script for ${JARVIS_CONTAINER_NAME}\n"
echo "✔ Setting credentials file"

CONFIG_PATH="${JARVIS_CONFIG_ROOT}/${JARVIS_CONTAINER_NAME}/config"
mkdir -p "$CONFIG_PATH"

cat >"$CONFIG_PATH/configuration.yml" <<EOL
server:
  address: tcp://:9091

log:
  level: debug

totp:
  issuer: ${JARVIS_DOMAIN}

identity_validation:
  reset_password:
    jwt_secret: ${JARVIS_AUTH_JWT_SECRET}

authentication_backend:
  file:
    path: /config/users_database.yml

access_control:
  default_policy: two_factor
  rules:
    - domain: ${JARVIS_DOMAIN}
      policy: bypass
    - domain: dashdot.${JARVIS_DOMAIN}
      policy: bypass
    - domain: alist.${JARVIS_DOMAIN}
      policy: bypass
    - domain: traefik.${JARVIS_DOMAIN}
      policy: one_factor

session:
  secret: ${JARVIS_AUTH_SESSION_KEY}
  cookies:
    - name: ${JARVIS_HOSTNAME}
      domain: ${JARVIS_DOMAIN}
      authelia_url: https://${JARVIS_CONTAINER_NAME}.${JARVIS_DOMAIN}
      expiration: 6 hour
      inactivity: 5 minutes

regulation:
  max_retries: 5
  find_time: 2 minutes
  ban_time: 5 minutes

storage:
  encryption_key: ${JARVIS_AUTH_STORAGE_KEY}
  local:
    path: /config/db.sqlite3

notifier:
  smtp:
    username: ${JARVIS_EMAIL}
    password: ${JARVIS_AUTH_GOOGLE_APP_PASSWORD}
    address: smtp://smtp.gmail.com:587
    sender: hi@${JARVIS_DOMAIN}
EOL

echo "✔ Setting database file"

HASHED_PASSWORD=$(echo -n "${JARVIS_ADMIN_PASSWORD}" | argon2 "$(openssl rand -hex 16)" -id -t 3 -m 12 -p 1 | awk '/Encoded:/ {print $2}')
DB_PATH="$CONFIG_PATH/users_database.yml"
{ [ -s "$DB_PATH" ] || cat >"$DB_PATH"; } <<EOL
users:
  ${JARVIS_ADMIN_USERNAME}:
    disabled: false
    displayname: ${JARVIS_ADMIN_NAME}
    password: ${HASHED_PASSWORD}
    email: ${JARVIS_ADMIN_EMAIL}
    groups:
      - admins
      - dev
EOL