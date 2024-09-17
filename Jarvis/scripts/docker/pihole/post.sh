echo -e "\n\n● Post script for ${JARVIS_CONTAINER_NAME}\n"

echo "✔ Seting local dns entries"
DNS_PATH="/etc/${JARVIS_CONTAINER_NAME}/dnsmasq.d/02-wildcard.conf"

docker exec ${JARVIS_CONTAINER_NAME} bash -c "echo 'address=/${JARVIS_DOMAIN}/${JARVIS_STATIC_IP}
address=/.${JARVIS_DOMAIN}/${JARVIS_STATIC_IP}' > $DNS_PATH"

echo "✔ Seting MAXCONN as 5096 to increase maximum allowed connections"
FTL_CONF_PATH="/etc/${JARVIS_CONTAINER_NAME}/pihole-FTL.conf"
docker exec ${JARVIS_CONTAINER_NAME} bash -c "grep -q '^MAXCONN=' $FTL_CONF_PATH && sed -i 's/^MAXCONN=.*/MAXCONN=5096/' $FTL_CONF_PATH || echo 'MAXCONN=5096' >> $FTL_CONF_PATH"

echo "✔ Restarting container"
docker restart ${JARVIS_CONTAINER_NAME} >/dev/null 2>&1 &
