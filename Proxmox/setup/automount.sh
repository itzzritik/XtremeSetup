#!/bin/bash -e

printf '\n+%166s+\n\n' | tr ' ' '-'
echo -e "● Creating auto mount entry for drive in Fstab\n"

if ! dpkg -l | grep -q "ntfs-3g"; then
    echo "→ NTFS support not found. Installing...\n"
    sudo apt install ntfs-3g -y
fi

declare -A DRIVES=(
    ["06BDD2E367CF2A57"]="/mnt/ssd"
    ["083AAA5A3AAA4492"]="/mnt/wdhdd"
)

for UUID in "${!DRIVES[@]}"; do
    MOUNT_POINT=${DRIVES[$UUID]}
    DEVICE=$(blkid -t UUID=$UUID -o device)

    [ -z "$DEVICE" ] && echo "✕ Drive with UUID=$UUID and Mount=$MOUNT_POINT not found!" && continue
    [ ! -d "$MOUNT_POINT" ] && mkdir -p "$MOUNT_POINT"

    FORMAT=$(blkid -s TYPE -o value $DEVICE)
    MODEL=$(udevadm info --query=property --name=$DEVICE | grep "ID_MODEL=" | cut -d '=' -f 2)
    echo "→ Found: Model=$MODEL, UUID=$UUID, Format=$FORMAT, Path=$DEVICE, Mount=$MOUNT_POINT"

    if grep -q "UUID=$UUID" /etc/fstab; then
        echo "✔ Removing existing $MODEL ($UUID) entry found in fstab"
        sed -i "\|UUID=$UUID|d" /etc/fstab
    fi

    echo "UUID=$UUID $MOUNT_POINT $FORMAT defaults,noatime,nodiratime,users,permissions 0 2" | sudo tee -a /etc/fstab >/dev/null
    echo -e "✔ Successfully created fstab entry\n"
done

systemctl daemon-reload
mount -a
echo "✔ All drives mounted successfully."