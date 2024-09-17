echo -e "\n\n● Post script for ${JARVIS_CONTAINER_NAME}\n"

export PGPASSWORD=${JARVIS_POSTGRES_PASSWORD}

echo "→ Waiting for ${JARVIS_CONTAINER_NAME}"
until docker exec "${JARVIS_CONTAINER_NAME}" pg_isready -U "${JARVIS_ADMIN_USERNAME}" > /dev/null 2>&1; do
  sleep 1
done

echo "✔ Create database → auth"
DB_NAME="auth"

if ! docker exec ${JARVIS_CONTAINER_NAME} psql -U ${JARVIS_ADMIN_USERNAME} -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='$DB_NAME'" | grep -q 1; then
  docker exec ${JARVIS_CONTAINER_NAME} psql -U ${JARVIS_ADMIN_USERNAME} -d postgres -c "CREATE DATABASE $DB_NAME;"
  echo "✔ Database $DB_NAME created"
else
  echo "✔ Database $DB_NAME already exists"
fi