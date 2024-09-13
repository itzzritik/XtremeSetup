#!/bin/bash -e

printf '\n+%131s+\n\n' | tr ' ' '-'
printf '● Setting up \e]8;;https://www.docker.com\e\\Docker\e]8;;\e\\\n\n'

[ $(id -u) -eq 0 ] && echo "✕ This script needs to run WITHOUT superuser permission" && exit 1

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
bash "$SCRIPT_DIR/prerequisites.sh"

printf '\n+%131s+\n\n' | tr ' ' '-'

APP_LIST=(
	"auth=https://www.authelia.com"
	"traefik=https://traefik.io/traefik"
	# "pihole=https://pi-hole.net"
	# "code=https://github.com/coder/code-server"
	"home=https://www.home-assistant.io"
	"alist=https://github.com/alist-org/alist"
	"duplicati=https://duplicati.com"
	"portainer=https://portainer.io"
	"homarr=https://homarr.dev"
	# "syncpihole=https://orbitalsync.com"
	"dashdot=https://getdashdot.com"
	"cloudflared=https://one.dash.cloudflare.com"
)

DEPLOY() {
	local NAME=$(echo "$1" | cut -d'=' -f1)
	local URL=$(echo "$1" | cut -d'=' -f2)
	local TITLE_NAME="${NAME^}"
	export JARVIS_CONTAINER_NAME=$NAME

	local COMPOSE_FILE="$SCRIPT_DIR/$NAME/compose.yml"
	local LOG_FILE="$SCRIPT_DIR/$NAME/deploy.log"

	docker stop "$NAME" >/dev/null 2>&1 && docker rm "$NAME" >/dev/null 2>&1
	docker compose -f "$COMPOSE_FILE" up -d --build >"$LOG_FILE" 2>&1

	if ! grep -iqE "error|warning" "$LOG_FILE"; then
		rm "$LOG_FILE"
		printf '✔ \e]8;;%s\a%s\e]8;;\a deployed successfully\n' "$URL" "$TITLE_NAME"
	else
		printf '✕ \e]8;;%s\a%s\e]8;;\a failed to deploy\n' "$URL" "$TITLE_NAME"
		return 1
	fi
}


for APP in "${APP_LIST[@]}"; do
	DEPLOY "$APP" &
done

echo -e "● Deploying docker apps in parallel\n"
wait

FAIL_COUNT=$(find "$SCRIPT_DIR" -type f -name 'deploy.log' | wc -l)
echo -e "\n✔ $((${#APP_LIST[@]} - FAIL_COUNT)) apps deployed successfully"

if [ $FAIL_COUNT -ne 0 ]; then
	echo -e "\n✕ $FAIL_COUNT apps failed to deploy"
	bash "$SCRIPT_DIR/logs.sh"
fi

echo -e "✔ Clearing docker cache"
docker system prune -af --volumes >/dev/null 2>&1 &
