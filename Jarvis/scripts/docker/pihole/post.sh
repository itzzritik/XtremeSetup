echo -e "\n\n● Post script for ${JARVIS_CONTAINER_NAME}\n"

echo "✔ Seting local dns entries"
CONFIG_PATH="${JARVIS_CONFIG_ROOT}/${JARVIS_CONTAINER_NAME}"
sudo chown -R $USER:$USER $CONFIG_PATH
sudo chmod -R 777 $CONFIG_PATH

DNS_PATH="$CONFIG_PATH/dnsmasq.d/02-wildcard.conf"
mkdir -p "$(dirname "$DNS_PATH")" && touch "$DNS_PATH"

cat <<EOF > "$DNS_PATH"
address=/${JARVIS_DOMAIN}/${JARVIS_STATIC_IP}
address=/.${JARVIS_DOMAIN}/${JARVIS_STATIC_IP}
EOF

echo "✔ Seting MAXCONN as 5096 to increase maximum allowed connections"
FTL_CONF_PATH="$CONFIG_PATH/pihole-FTL.conf"
CONFIGS=("MAXCONN=5096" "RATE_LIMIT=5000/60")

touch "$FTL_CONF_PATH"
for CONFIG in "${CONFIGS[@]}"; do
    KEY=$(echo "$CONFIG" | cut -d '=' -f 1)
    grep -q "^$KEY=" "$FTL_CONF_PATH" && sed -i "s/^$KEY=.*/$CONFIG/" "$FTL_CONF_PATH" || echo "$CONFIG" >> "$FTL_CONF_PATH"
done

echo "✔ Restarting container"
docker restart ${JARVIS_CONTAINER_NAME} >/dev/null 2>&1 &
