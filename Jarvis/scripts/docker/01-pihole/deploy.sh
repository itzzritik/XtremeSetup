#!/bin/bash -e

NAME=PiHole
CONTAINER_NAME="${NAME,,}"
URL=https://pi-hole.net
export JARVIS_CONTAINER_NAME=$CONTAINER_NAME

printf '\n+%131s+\n\n' | tr ' ' '-'
printf '⚪ Deploying \e]8;;%s\a%s\e]8;;\a in Docker\n' "$URL" "$NAME"
echo

[ $(id -u) -eq 0 ] && echo "⛔ This script needs to run WITHOUT superuser permission" && exit 1

[ -z "$(command -v docker)" ] && echo "⛔ Docker not found, Install it first!" && exit 1

if docker ps --filter "name=$CONTAINER_NAME" --filter "status=running" --format "{{.Names}}" | grep -q "^$CONTAINER_NAME$"; then
    echo "✔ Container already up and running" && exit 0
fi

CREATE_DIRS=("$JARVIS_CONFIG_ROOT/$CONTAINER_NAME")
for DIR in ${CREATE_DIRS[*]}; do mkdir -p "$DIR"; done

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"

echo "→ Removing existing containers"
echo
docker compose -f $SCRIPT_DIR/compose.yml rm -s -f
echo
echo "→ Deploying new containers"
echo
docker compose -f $SCRIPT_DIR/compose.yml up -d
echo

echo "✔ Seting local dns entries"
DNS_PATH="/etc/$CONTAINER_NAME/custom.list"
SUBDOMAINS=(
    ""
    "traefik"
    "pihole"
    "code"
    "home"
    "alist"
    "duplicati"
    "portainer"
    "dashdot"
)
for SUBDOMAIN in "${SUBDOMAINS[@]}"; do
    ENTRY="$JARVIS_STATIC_IP ${SUBDOMAIN:+$SUBDOMAIN.}$JARVIS_DOMAIN"
    docker exec $CONTAINER_NAME bash -c "grep -Fq '${ENTRY}' $DNS_PATH || echo '${ENTRY}' >> $DNS_PATH"
done

FTL_CONF_PATH="/etc/$CONTAINER_NAME/pihole-FTL.conf"
docker exec $CONTAINER_NAME bash -c "grep -q '^MAXCONN=' $FTL_CONF_PATH && sed -i 's/^MAXCONN=.*/MAXCONN=5096/' $FTL_CONF_PATH || echo 'MAXCONN=5096' >> $FTL_CONF_PATH"

docker restart $CONTAINER_NAME > /dev/null 2>&1 &
echo "✔ $NAME deployed successfully"


