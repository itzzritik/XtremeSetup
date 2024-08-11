SCRIPT_DIR="$( cd "$( dirname "$(readlink -f "$0")" )" && pwd )"

echo "
TZ=$(timedatectl | grep 'Time zone' | awk '{print $3}')
ROOT=$JARVIS_DRIVE_ROOT
CONFIG=$JARVIS_CONFIG_ROOT
PUID=$(id -u $USER)
PGID=$(id -g $USER)
" | tee $SCRIPT_DIR/.env > /dev/null