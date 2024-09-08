#!/bin/bash -e

printf '\n+%131s+\n\n' | tr ' ' '-'
echo -e "⚪ Running docker post scripts\n"

# ALIST
echo "→ Alist"
docker exec -it alist ./alist password set "$JARVIS_PASSWORD" >/dev/null 2>&1
docker restart alist >/dev/null 2>&1
echo -e "✔ Alist password set successfully\n"

# PIHOLE
echo "→ PiHole"
while [ "$(docker inspect -f '{{.State.Health.Status}}' pihole)" != "healthy" ]; do
    [ -z "$dots" ] && dots=""; echo -ne "  → Waiting for container to show up${dots}\r"; dots="${dots}."; sleep 1
done
declare -A CUSTOM_DNS=(
    ["pihole.myjarvis.in"]=192.168.68.255
    ["home.myjarvis.in"]=192.168.68.255
    ["code.myjarvis.in"]=192.168.68.255
    ["jarvis.com"]=192.168.68.255
)
for HOST in "${!CUSTOM_DNS[@]}"; do
    IP=${CUSTOM_DNS[$HOST]}
    docker exec -it pihole bash -c "echo \"${IP} ${HOST}\" >> /etc/custom.list"
done
docker restart pihole >/dev/null 2>&1
echo -e "\r\033[K✔ Custom DNS entries added to Pi-hole\n"

# CLEANUP
echo "→ Clearing docker cache (this may take a while)"
docker container prune -f >/dev/null 2>&1
docker volume prune -f >/dev/null 2>&1
docker network prune -f >/dev/null 2>&1
docker image prune -a -f >/dev/null 2>&1
docker builder prune -f >/dev/null 2>&1
