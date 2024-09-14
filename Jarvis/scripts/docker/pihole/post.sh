echo "✔ Seting local dns entries"

JARVIS_DOCKER_APPS=(
	"auth=https://www.authelia.com"
	"traefik=https://traefik.io/traefik"
	"pihole=https://pi-hole.net"
	"code=https://github.com/coder/code-server"
	"home=https://home-assistant.io"
	"alist=https://github.com/alist-org/alist"
	"duplicati=https://duplicati.com"
	"portainer=https://portainer.io"
	"homarr=https://homarr.dev"
	"syncpihole=https://orbitalsync.com"
	"dashdot=https://getdashdot.com"
	"dozzle=https://dozzle.dev"
	"cloudflared=https://one.dash.cloudflare.com"
)
DNS_PATH="/etc/$JARVIS_CONTAINER_NAME/custom.list"

for APP in "${JARVIS_DOCKER_APPS[@]}"; do
	SUBDOMAIN=$(echo "$1" | cut -d'=' -f1)
	ENTRY="$JARVIS_STATIC_IP ${SUBDOMAIN:+$SUBDOMAIN.}$JARVIS_DOMAIN"
	docker exec $JARVIS_CONTAINER_NAME bash -c "grep -Fq '${ENTRY}' $DNS_PATH || echo '${ENTRY}' >> $DNS_PATH"
done

FTL_CONF_PATH="/etc/$JARVIS_CONTAINER_NAME/pihole-FTL.conf"
docker exec $JARVIS_CONTAINER_NAME bash -c "grep -q '^MAXCONN=' $FTL_CONF_PATH && sed -i 's/^MAXCONN=.*/MAXCONN=5096/' $FTL_CONF_PATH || echo 'MAXCONN=5096' >> $FTL_CONF_PATH"

docker restart $JARVIS_CONTAINER_NAME >/dev/null 2>&1 &
