#!/bin/bash -e

printf '\n+%131s+\n\n' | tr ' ' '-'
printf '● Setting up \e]8;;https://www.docker.com\e\\Docker\e]8;;\e\\\n\n'

[ $(id -u) -eq 0 ] && echo "✕ This script needs to run WITHOUT superuser permission" && exit 1

JARVIS_DOCKER_APPS=(
	"code=https://github.com/coder/code-server"
	# "auth=https://www.authelia.com"
	"traefik=https://traefik.io/traefik"
	"pihole=https://pi-hole.net"
	"home=https://home-assistant.io"
	"alist=https://github.com/alist-org/alist"
	"duplicati=https://duplicati.com"
	"portainer=https://portainer.io"
	"homarr=https://homarr.dev"
	# "syncpihole=https://orbitalsync.com"
	"dashdot=https://getdashdot.com"
	"dozzle=https://dozzle.dev"
	"cloudflared=https://one.dash.cloudflare.com"
)
MAX_APP_CHAR=$(printf "%s\n" "${JARVIS_DOCKER_APPS[@]}" | cut -d'=' -f1 | wc -L)
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
bash "$SCRIPT_DIR/prerequisites.sh" || exit 1

DEPLOY() {
	local NAME=$(echo "$1" | cut -d'=' -f1)
	local URL=$(echo "$1" | cut -d'=' -f2)
	local TITLE_NAME="${NAME^}"
	export JARVIS_CONTAINER_NAME=$NAME

	local LOG_FILE="$SCRIPT_DIR/$NAME/deploy.log"
	local COMPOSE="$SCRIPT_DIR/$NAME/compose.yml"
	local PRE="$SCRIPT_DIR/$NAME/pre.sh"
	local POST="$SCRIPT_DIR/$NAME/post.sh"

	> "$LOG_FILE"

	REQUIRED_VARS=$(grep -hoP '\$\{\K[a-zA-Z0-9_]+(?=\})' "$COMPOSE" "$PRE" "$POST" 2>/dev/null | sort -u)
	for VAR in $REQUIRED_VARS; do [ -z "${!VAR}" ] && printf '✕ %-*s  →  %-30s\n' "$MAX_APP_CHAR" "$TITLE_NAME" "Variable $VAR not set" | tee -a "$LOG_FILE" && return 1; done
	
	if docker ps --filter "name=$NAME" --filter "status=running" --format "{{.Names}}" | grep -q "^$NAME$"; then
		TIME=$(docker ps --filter "name=$NAME" --format "{{.Status}}" | awk '{print $2 substr($3,1,1)}')
		printf '✔ %-*s  →  Running (%s)\n' "$MAX_APP_CHAR" "$TITLE_NAME" "$TIME" && rm -f "$LOG_FILE" && return 0
	fi

	mkdir -p "$JARVIS_CONFIG_ROOT/$NAME"
	[ -f "$PRE" ] && bash "$PRE" >>"$LOG_FILE" 2>&1
	docker stop "$NAME" >/dev/null 2>&1 && docker rm "$NAME" >/dev/null 2>&1
	docker compose -f "$COMPOSE" up -d --build >>"$LOG_FILE" 2>&1
	[ -f "$POST" ] && bash "$POST" >>"$LOG_FILE" 2>&1

	if ! grep -qiE "✕|error|warning|cannot|failed|exception|fatal|critical" "$LOG_FILE"; then
		printf '✔ %-*s  →  Deployed\n' "$MAX_APP_CHAR" "$TITLE_NAME" && rm -f "$LOG_FILE" && return 0
	else
		printf '✔ %-*s  →  Failed to deploy\n' "$MAX_APP_CHAR" "$TITLE_NAME" && return 1
	fi
}

echo -e "● Deploying docker apps in parallel\n"

for APP in "${JARVIS_DOCKER_APPS[@]}"; do DEPLOY "$APP" & done

wait

FAIL_COUNT=$(find "$SCRIPT_DIR" -type f -name 'deploy.log' | wc -l)
echo -e "\n✔ $((${#JARVIS_DOCKER_APPS[@]} - FAIL_COUNT)) apps are up and running"

if [ $FAIL_COUNT -ne 0 ]; then
	echo -e "✕ $FAIL_COUNT apps failed to deploy"
	bash "$SCRIPT_DIR/logs.sh"
fi

echo -e "✔ Clearing docker cache"
docker system prune -af --volumes >/dev/null 2>&1 &
