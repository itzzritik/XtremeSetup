#!/bin/bash -e

printf '\n+%131s+\n\n' | tr ' ' '-'
echo -e "⚪ Running docker post scripts\n"

echo "→ Alist"
docker exec -it alist ./alist password set "$JARVIS_PASSWORD" >/dev/null 2>&1
docker restart alist >/dev/null 2>&1
echo -e "✔ Alist password set successfully\n"

echo "→ PiHole"
while [ "$(docker inspect -f '{{.State.Health.Status}}' pihole)" != "healthy" ]; do
    [ -z "$dots" ] && dots=""; echo -ne "  → Waiting for container to show up${dots}\r"; dots="${dots}."; sleep 1
done
docker exec pihole /bin/bash -c "sed -i 's/server.port\s*=\s*80/server.port = 7777/' /etc/lighttpd/lighttpd.conf"
docker restart pihole >/dev/null 2>&1
echo -e "\r\033[K✔ Pihole port set to 7777\n"

echo "→ Removing unused docker images"
docker image prune -a -f >/dev/null 2>&1