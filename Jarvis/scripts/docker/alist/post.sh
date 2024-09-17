echo -e "\n\n● Post script for ${JARVIS_CONTAINER_NAME}\n"

echo "✔ Setting password"
docker exec -it ${JARVIS_CONTAINER_NAME} ./${JARVIS_CONTAINER_NAME} password set "${JARVIS_ADMIN_PASSWORD}" >/dev/null 2>&1

echo "✔ Restarting container"
docker restart ${JARVIS_CONTAINER_NAME} >/dev/null 2>&1 &
