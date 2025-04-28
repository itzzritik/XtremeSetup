#!/bin/bash -e

printf '\n+%131s+\n\n' | tr ' ' '-'
echo -e "● Setting static ip for Jarvis\n"

[ $(id -u) -eq 0 ] && echo "✕ This script needs to run WITHOUT superuser permission" && exit 1

GATEWAY="192.168.68.1"
CONFIG_FILE="/etc/netplan/static.yaml"
CURRENT_IP=$(sudo grep -A 1 "addresses:" "$CONFIG_FILE" 2>/dev/null | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -n 1 || echo "")

[[ "$CURRENT_IP" == "$JARVIS_STATIC_IP" ]] && echo "✔ Static IP is already set to $JARVIS_STATIC_IP" && exit 0

sudo tee "$CONFIG_FILE" >/dev/null <<EOL
network:
  version: 2
  ethernets:
    eth0:
      addresses:
        - $JARVIS_STATIC_IP/24
      routes:
        - to: default
          via: $GATEWAY
      nameservers:
        addresses:
          - $(echo "$JARVIS_GOOGLE_DNS" | sed 's/;/\n          - /')
      dhcp4: no
EOL

echo "✔ Netplan configuration updated. applying changes..."
sudo chmod 600 "$CONFIG_FILE"
sudo netplan apply
echo "✔ Netplan changes applied successfully"


# arch: amd64
# cores: 4
# dev0: /dev/dri/card1,gid=44
# dev1: /dev/dri/renderD128,gid=104
# features: keyctl=1,nesting=1
# hostname: jellyfin
# memory: 2048
# net0: name=eth0,bridge=vmbr0,hwaddr=BC:24:11:4A:8E:43,ip=192.168.68.254/24,gw=192.168.68.1,type=veth
# onboot: 1
# ostype: ubuntu
# rootfs: local-lvm:vm-101-disk-0,size=8G
# swap: 512
# tags: community-script;media
# unprivileged: 1
# mp0: /mnt/wdhdd,mp=/media/wdhdd
# mp1: /mnt/ssd,mp=/media/ssd
# lxc.cgroup2.devices.allow: c 226:* rwm
# lxc.mount.entry: /dev/dri dev/dri none bind,optional

# arch: amd64
# cores: 2
# features: keyctl=1,nesting=1
# hostname: torrent
# memory: 2048
# mp0: /mnt/wdhdd,mp=/media/wdhdd
# mp1: /mnt/ssd,mp=/media/ssd
# net0: name=eth0,bridge=vmbr0,hwaddr=BC:24:11:10:B2:A7,ip=192.168.68.253/24,gw=192.168.68.1,type=veth
# onboot: 1
# ostype: debian
# rootfs: local-lvm:vm-102-disk-0,size=8G
# swap: 512
# tags: community-script;torrent
# unprivileged: 1
