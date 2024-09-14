#!/bin/bash -e

printf '\n+%131s+\n\n' | tr ' ' '-'
printf '● Setting up \e]8;;https://www.docker.com\e\\Docker\e]8;;\e\\\n\n'

[ $(id -u) -eq 0 ] && echo "✕ This script needs to run WITHOUT superuser permission" && exit 1

JARVIS_DOCKER_APPS=(
	"auth=https://www.authelia.com"
	"traefik=https://traefik.io/traefik"
	"pihole=https://pi-hole.net"
	"code=https://github.com/coder/code-server"
	"home=https://home-assistant.io"
	"alist=https://github.com/alist-org/alist"
	"duplicati=https://duplicati.com"
	"portainer=https://portainer.io"
	"homarr=https://homarr.dev"
	"syncpihole=https://orbitalsync.com"
	"dashdot=https://getdashdot.com"
	"tools=https://it-tools.tech"
	"cloudflared=https://one.dash.cloudflare.com"
)
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
bash "$SCRIPT_DIR/prerequisites.sh" || exit 1

DEPLOY() {
	local NAME=$(echo "$1" | cut -d'=' -f1)
	local URL=$(echo "$1" | cut -d'=' -f2)
	local TITLE_NAME="${NAME^}"
	local LOG_FILE="$SCRIPT_DIR/$NAME/deploy.log"
	local PRE="$SCRIPT_DIR/$NAME/pre.sh"
	local POST="$SCRIPT_DIR/$NAME/post.sh"
	export JARVIS_CONTAINER_NAME=$NAME

	if docker ps --filter "name=$NAME" --filter "status=running" --format "{{.Names}}" | grep -q "^$NAME$"; then
		TIME=$(docker ps --filter "name=$NAME" --format "{{.Status}}" | awk '{print $2 substr($3,1,1)}')
		echo "✔ $TITLE_NAME running since $TIME" && return 0
	fi

	mkdir -p "$JARVIS_CONFIG_ROOT/$NAME"
	[ -f "$PRE" ] && bash "$PRE" >"$LOG_FILE" 2>&1
	docker stop "$NAME" >/dev/null 2>&1 && docker rm "$NAME" >/dev/null 2>&1
	docker compose -f "$SCRIPT_DIR/$NAME/compose.yml" up -d --build >"$LOG_FILE" 2>&1
	[ -f "$POST" ] && bash "$POST" >"$LOG_FILE" 2>&1

	if ! grep -iqE "✕|error|warning|cannot" "$LOG_FILE"; then
		rm -f "$LOG_FILE"
		printf '✔ \e]8;;%s\a%s\e]8;;\a deployed\n' "$URL" "$TITLE_NAME"
	else
		printf '✕ \e]8;;%s\a%s\e]8;;\a failed to deploy\n' "$URL" "$TITLE_NAME" && return 1
	fi
}

for APP in "${JARVIS_DOCKER_APPS[@]}"; do
	DEPLOY "$APP" &
done

echo -e "● Deploying docker apps in parallel\n"
wait

FAIL_COUNT=$(find "$SCRIPT_DIR" -type f -name 'deploy.log' | wc -l)
echo -e "\n✔ $((${#JARVIS_DOCKER_APPS[@]} - FAIL_COUNT)) apps are up and running"

if [ $FAIL_COUNT -ne 0 ]; then
	echo -e "\n✕ $FAIL_COUNT apps failed to deploy"
	bash "$SCRIPT_DIR/logs.sh"
fi

echo -e "✔ Clearing docker cache"
docker system prune -af --volumes >/dev/null 2>&1 &
