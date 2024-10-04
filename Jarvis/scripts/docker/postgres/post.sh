#!/bin/bash -e

echo -e "\n\n● Post script for ${JARVIS_CONTAINER_NAME}\n"

echo "→ Waiting for ${JARVIS_CONTAINER_NAME}"
TIMEOUT=60;
while ! docker exec ${JARVIS_CONTAINER_NAME} psql -U ${JARVIS_ADMIN_USERNAME} -d postgres -c '\q' 2>/dev/null && [ $TIMEOUT -gt 0 ]; do sleep 1; ((TIMEOUT--)); done
[ $TIMEOUT -le 0 ] && echo "✕ Container did not come up within 60 seconds" && exit 1

sleep 5
export PGPASSWORD=${JARVIS_POSTGRES_PASSWORD}

if docker exec ${JARVIS_CONTAINER_NAME} psql -U ${JARVIS_ADMIN_USERNAME} -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='auth'" | grep -q 1; then
	echo "✔ Ensured databases" && sleep 1 && exit 0
fi

echo "→ Restoring postgress from dump"
docker exec -i ${JARVIS_CONTAINER_NAME} psql -U ${JARVIS_ADMIN_USERNAME} -f "/dump/dump.sql" 2>&1 | sed 's/ERROR//g'