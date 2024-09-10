NAME=Doppler
NAME_LOWER="${NAME,,}"
URL="https://www.doppler.com"

printf '\n+%131s+\n\n' | tr ' ' '-'
printf '⚪ Setup jarvis environment with \e]8;;%s\a%s\e]8;;\a\n\n' "$URL" "$NAME_LOWER"

if ! command -v "$NAME_LOWER" &> /dev/null; then
    echo -e "→ Installing $NAME_LOWER cli\n"

    sudo apt-get update && sudo apt-get install -y apt-transport-https ca-certificates curl gnupg
    curl -sLf --retry 3 --tlsv1.2 --proto "=https" 'https://packages.doppler.com/public/cli/gpg.DE2A7741A397C129.key' | sudo apt-key add -
    echo "deb https://packages.doppler.com/public/cli/deb/debian any-version main" | sudo tee /etc/apt/sources.list.d/doppler-cli.list
    sudo apt-get update && sudo apt-get install -y $NAME_LOWER

    [ ! command -v "$NAME_LOWER" &> /dev/null ] && echo -e "\n⛔ $NAME cli installation failed\n" && exit 1;
    echo -e "\n✔ $NAME cli installed successfully\n"
fi

if ! doppler me &> /dev/null; then
    echo "→ Authenticate $NAME_LOWER cli"
    doppler login
fi

set -a

JARVIS_HOSTNAME="jarvis"
JARVIS_DOMAIN="myjarvis.in"
JARVIS_GOOGLE_DNS="8.8.8.8;8.8.4.4"
JARVIS_STATIC_IP="192.168.68.255"
JARVIS_CERT_RESOLVER="letsencrypt"
JARVIS_TZ="Asia/Kolkata"
JARVIS_PUID=$(id -u $USER)
JARVIS_PGID=$(id -g $USER)
JARVIS_USER_NAME="Jarvis"
JARVIS_USER_EMAIL="ritik.jarvis@gmail.com"
JARVIS_PROXY_DOCKER_NETWORK="proxy"
JARVIS_DRIVE_ROOT="/mnt/drive1"
JARVIS_CONFIG_ROOT="$JARVIS_DRIVE_ROOT/.configs"

echo "✔ Environment variables injected into the shell"
source <(doppler secrets download -p "$JARVIS_HOSTNAME" -c prd --silent --enable-dns-resolver --no-file --format env)
echo "✔ $NAME secrets injected into the shell"

set +a