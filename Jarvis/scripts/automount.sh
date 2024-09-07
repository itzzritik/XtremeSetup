#!/bin/bash -e

printf '\n+%131s+\n\n' | tr ' ' '-'
echo -e "⚪ Creating auto mount entry for drive in Fstab\n"

[ $(id -u) -eq 0 ] && echo "⛔ This script needs to run WITHOUT superuser permission" && exit 1

if ! dpkg -l | grep -q "ntfs-3g"; then
    echo "→ NTFS support not found. Installing...\n"
    sudo apt install ntfs-3g -y
fi

[ -z "$JARVIS_DRIVE_ROOT" ] && echo "⛔ Env variable \"JARVIS_DRIVE_ROOT\" not set!" && exit 1

declare -A DRIVES=(
    ["083AAA5A3AAA4492"]="$JARVIS_DRIVE_ROOT"
)

echo -e "✔ Adding prevent sleep cron job"
SLEEP_TEXT="prevent sleep"
DISABLE_SLEEP_CRON="*/5 * * * * /bin/bash -c 'for mount_point in ${DRIVES[@]}; do counter_file=\"\$mount_point/.keepawake\"; if [ -f \"\$counter_file\" ]; then counter=\$(grep -o \"[0-9]*\" \"\$counter_file\" || echo 0); else counter=0; fi; counter=\$((counter + 1)); echo \"$SLEEP_TEXT \$counter\" > \"\$counter_file\"; done'"
(crontab -l 2>/dev/null | grep -vF "$SLEEP_TEXT"; echo "$DISABLE_SLEEP_CRON") | crontab -

ALL_MOUNTED=true
for UUID in "${!DRIVES[@]}"; do [[ -z $(findmnt --fstab --target ${DRIVES[$UUID]} -A) ]] && ALL_MOUNTED=false && break; done
[[ $ALL_MOUNTED == true ]] && echo "✔ All drives are already mounted" && exit 0

for UUID in "${!DRIVES[@]}"; do
    MOUNT_POINT=${DRIVES[$UUID]}
    DEVICE=$(blkid -t UUID=$UUID -o device)

    [ -z "$DEVICE" ] && echo "✕ Drive with UUID=$UUID and Mount=$MOUNT_POINT not found!" && continue
    [ ! -d "$MOUNT_POINT" ] && sudo mkdir -p "$MOUNT_POINT"

    FORMAT=$(blkid -s TYPE -o value $DEVICE)
    MODEL=$(udevadm info --query=property --name=$DEVICE | grep "ID_MODEL=" | cut -d '=' -f 2)
    echo "→ Found: Model=$MODEL, UUID=$UUID, Format=$FORMAT, Path=$DEVICE, Mount=$MOUNT_POINT"

    if grep -q "UUID=$UUID" /etc/fstab; then
        echo "✔ Removing existing $MODEL ($UUID) entry found in fstab"
        sudo sed -i "\|UUID=$UUID|d" /etc/fstab
    fi

    echo "UUID=$UUID $MOUNT_POINT $FORMAT defaults,noatime,nodiratime 0 0" | sudo tee -a /etc/fstab >/dev/null
    echo -e "✔ Successfully created fstab entry\n"
done

sudo systemctl daemon-reload
sudo mount -a
sudo chown -R $USER:$USER /mnt
sudo chmod -R u+rwx /mnt
echo "✔ Mount point permissions set for user: $USER"

[[ ! $(sudo findmnt --fstab --target "$JARVIS_DRIVE_ROOT" -A) ]] && echo "⛔ Mounting failed. Check configuration." && exit 1
echo "✔ All drives mounted successfully."