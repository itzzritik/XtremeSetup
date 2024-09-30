echo -e "\n\n● Post script for ${JARVIS_CONTAINER_NAME}\n"

echo "→ Waiting for ${JARVIS_CONTAINER_NAME}"
TIMEOUT=60; ELAPSED=0
until docker exec "${JARVIS_CONTAINER_NAME}" pg_isready -U "${JARVIS_ADMIN_USERNAME}" >/dev/null 2>&1 || [ "$ELAPSED" -ge "$TIMEOUT" ]; do
    sleep 1; ((ELAPSED++))
done || { echo "✕ Container did not come up within $TIMEOUT seconds"; exit 1; }

sleep 5;

export PGPASSWORD=${JARVIS_POSTGRES_PASSWORD}
DB_LIST=(
	auth
)

for DB_NAME in "${DB_LIST[@]}"; do
	if docker exec ${JARVIS_CONTAINER_NAME} psql -U ${JARVIS_ADMIN_USERNAME} -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='$DB_NAME'" | grep -q 1; then
		echo "✔ Database $DB_NAME already exists" && continue
	fi
	docker exec ${JARVIS_CONTAINER_NAME} psql -U ${JARVIS_ADMIN_USERNAME} -d postgres -c "CREATE DATABASE $DB_NAME;"
	echo "✔ Database $DB_NAME created"
done
echo "✔ Ensured all databases"