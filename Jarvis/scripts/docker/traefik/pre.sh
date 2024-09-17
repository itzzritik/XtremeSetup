echo -e "\n\n● Pre script for ${JARVIS_CONTAINER_NAME}\n"

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
CONFIG_PATH="${JARVIS_CONFIG_ROOT}/${JARVIS_CONTAINER_NAME}"

echo "✔ Create required directories"
for DIR in logs data rules; do mkdir -p "$CONFIG_PATH/$DIR"; done

echo "✔ Applying static configurations"
CLOUDFLARE_IPS=$(curl -s https://www.cloudflare.com/ips-v4 | sed 's/^/        - "/;s/$/"/')
envsubst <"$SCRIPT_DIR/configs/traefik.yml" >"$CONFIG_PATH/traefik.yml"
sed -i "/# Cloudflare IPs/r /dev/stdin" "$CONFIG_PATH/traefik.yml" <<<"$CLOUDFLARE_IPS"

echo "✔ Applying dynamic rules and middleware configurations"
for RULE_FILE in "$SCRIPT_DIR/configs/rules/"*.yml; do
	echo "$RULE_FILE $CONFIG_PATH/rules/$(basename "$RULE_FILE")"
	envsubst <"$RULE_FILE" >"$CONFIG_PATH/rules/$(basename "$RULE_FILE")"
done

echo "✔ Set right rules to acme.json"
ACME="$CONFIG_PATH/data/acme.json"
[ -e "$ACME" ] || touch "$ACME" && sudo chmod 600 "$ACME"
[ "$(stat -c "%a" "$ACME")" -ne 600 ] && echo "✕ Failed to set permissions 600 for acme.json"