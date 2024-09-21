echo -e "\n\n● Pre script for ${JARVIS_CONTAINER_NAME}\n"

echo "✔ Setting 600 permission to acme.json"

ACME="${JARVIS_CONFIGS}/${JARVIS_CONTAINER_NAME}/data/acme.json"
[ -e "$ACME" ] || touch "$ACME"
sudo chmod 600 "$ACME"

[ "$(stat -c "%a" "$ACME")" -ne 600 ] && echo "✕ Failed to set permissions"