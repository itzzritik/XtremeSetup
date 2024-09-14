printf '\n+%131s+\n\n' | tr ' ' '-'
echo -e "● Post script for $JARVIS_CONTAINER_NAME\n"
echo "✔ Setting password"

REQUIRED_VARS=(
    "JARVIS_CONTAINER_NAME"
    "JARVIS_ADMIN_PASSWORD"
)
for VAR in "${REQUIRED_VARS[@]}"; do [ -z "${!VAR}" ] && echo "✕ Env variable \"$VAR\" not set!" && exit 1; done

docker exec -it $JARVIS_CONTAINER_NAME ./$JARVIS_CONTAINER_NAME password set "$JARVIS_ADMIN_PASSWORD" >/dev/null 2>&1
docker restart $JARVIS_CONTAINER_NAME >/dev/null 2>&1 &
