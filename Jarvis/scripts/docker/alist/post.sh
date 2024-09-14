echo "✔ Setting password for $JARVIS_CONTAINER_NAME"

docker exec -it $JARVIS_CONTAINER_NAME ./$JARVIS_CONTAINER_NAME password set "$JARVIS_ADMIN_PASSWORD" >/dev/null 2>&1
docker restart $JARVIS_CONTAINER_NAME >/dev/null 2>&1 &
