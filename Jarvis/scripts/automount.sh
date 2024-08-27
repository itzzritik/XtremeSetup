#!/bin/bash -e

printf '\n+%131s+\n\n' | tr ' ' '-'
echo "⚪ Creating auto mount entry for drive in Fstab"
echo

[ $(id -u) -eq 0 ] && echo "⛔ This script needs to run WITHOUT superuser permission" && exit 1

if ! dpkg -l | grep -q "ntfs-3g"; then
    echo "→ NTFS support not found. Installing...\n"
    sudo apt install ntfs-3g -y
fi

[ -z "$JARVIS_DRIVE_ROOT" ] && echo "⛔ Env variable \"JARVIS_DRIVE_ROOT\" not set!" && exit 1


declare -A DRIVES=(
    ["083AAA5A3AAA4492"]="$JARVIS_DRIVE_ROOT"
)

ALL_MOUNTED=true
for UUID in "${!DRIVES[@]}"; do [[ -z $(findmnt --fstab --target ${DRIVES[$UUID]} -A) ]] && ALL_MOUNTED=false && break; done
[[ $ALL_MOUNTED == true ]] && echo "✔ All drives are already mounted" && exit 0

for UUID in "${!DRIVES[@]}"; do
    echo
    MOUNT_POINT=${DRIVES[$UUID]}
    DEVICE=$(blkid -t UUID=$UUID -o device)

    [ -z "$DEVICE" ] && echo "✕ Drive with UUID=$UUID and Mount=$MOUNT_POINT not found!" && continue
    
    [ ! -d "$MOUNT_POINT" ] && sudo mkdir -p "$MOUNT_POINT"

    FORMAT=$(blkid -s TYPE -o value $DEVICE)
    MODEL=$(udevadm info --query=property --name=$DEVICE | grep "ID_MODEL=" | cut -d '=' -f 2)

    echo "→ Found: Model=$MODEL, UUID=$UUID, Format=$FORMAT, Path=$DEVICE, Mount=$MOUNT_POINT"

    # Remove existing entry from fstab
    if grep -q "UUID=$UUID" /etc/fstab; then
        echo "✔ Removing existing $MODEL ($UUID) entry found in fstab"
        sudo sed -i "\|UUID=$UUID|d" /etc/fstab
    fi

    # Add the mount entry to fstab
    echo "UUID=$UUID $MOUNT_POINT $FORMAT default 0 0" | sudo tee -a /etc/fstab >/dev/null
    echo "✔ Successfully created fstab entry"
done
echo

# Mount all drives in /etc/fstab
sudo systemctl daemon-reload
sudo mount -a

# Allow mount point read-write permission to current user
sudo chown -R $USER:$USER /mnt
sudo chmod -R u+rwx /mnt
echo "✔ Allow mount point read-write permission to user: $USER"

if [[ $(sudo findmnt --fstab --target $JARVIS_DRIVE_ROOT -A) ]]; then
    echo "✔ All drives mounted succesfully" && exit 0
else
    echo "⛔ Oops! Automounting not working! please check"
fi
