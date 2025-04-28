printf '● Setup environment with \e]8;;%s\a%s\e]8;;\a\n\n' "$URL" "$NAME_LOWER"

set -a

PROXMOX_HOSTNAME="jarvis"


PROXMOX_ADMIN_USERNAME=$(echo "${PROXMOX_ADMIN_NAME}" | awk '{print tolower($1)}')
PROXMOX_ADMIN_PASSWORD_HASHED=$(htpasswd -nbB admin "$PROXMOX_ADMIN_PASSWORD" | awk -F: '{print $2}')
PROXMOX_DOMAIN="myjarvis.in"
PROXMOX_GOOGLE_DNS="8.8.8.8;8.8.4.4"
PROXMOX_STATIC_IP="192.168.68.255"
PROXMOX_CERT_RESOLVER="letsencrypt"
PROXMOX_TZ="Asia/Kolkata"
PROXMOX_PUID=$(id -u $USER)
PROXMOX_PGID=$(id -g $USER)
PROXMOX_EMAIL="ritik.jarvis@gmail.com"
PROXMOX_PROXY_DOCKER_NETWORK="proxy"
PROXMOX_DRIVE_ROOT="/mnt/drive1"
PROXMOX_CONFIGS="$HOME/.$PROXMOX_HOSTNAME/configs"
PROXMOX_LOGS="$HOME/.$PROXMOX_HOSTNAME/logs"

echo "✔ Environment variables injected into the shell"
set +a