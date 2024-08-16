#!/bin/bash -e

printf '\n+%131s+\n\n' | tr ' ' '-'
printf '⚪ Mounting configuration bucket (\e]8;;https://developers.cloudflare.com/r2\e\\Cloudflare R2\e]8;;\e\\) using \e]8;;https://github.com/rclone/rclone\e\\RClone\e]8;;\e\\\n'
echo

# Check super user permission
if [ $(id -u) -eq 0 ]; then
    echo "⛔ This script needs to run WITHOUT superuser permission"
    exit 1
fi

MOUNT_POINT="/mnt/configs"
SYSTEMD_MOUNT_UNIT="jarvis-configs.service"
SYSTEMD_MOUNT="/etc/systemd/system/"$SYSTEMD_MOUNT_UNIT""
# SYNC_IGNORE="jellyfin/data/metadata/library|radarr/logs|radarr/Backups|sonarr/logs|sonarr/Backups|bazarr/logs|bazarr/backups|bazarr/cache"

# Check if bucket is already mounted
if mount | grep -q "$MOUNT_POINT"; then
    echo "✔ Config bucket is already mounted at $MOUNT_POINT"
    exit 1
fi

# Install RClone if not already
if [[ $(which rclone ) && $(rclone --version) ]];
then
    echo "✔ RClone is already installed"
else
    echo "Installing RClone..."
    sudo -v ; curl https://rclone.org/install.sh | sudo bash
    echo
    echo "✔ RClone installed successfully"
    echo
fi

# Create RClone config file
CREDS="$HOME/.config/rclone/rclone.conf"

if [ ! -f "$CREDS" ]; then
read -p "Enter the Access Key ID: " ACCESS_KEY_ID
read -p "Enter the Secret Access Key: " SECRET_ACCESS_KEY
read -p "Enter the Endpoint: " ENDPOINT

touch "$CREDS"

echo "[jarvis]
type = s3
provider = Cloudflare
access_key_id = $ACCESS_KEY_ID
secret_access_key = $SECRET_ACCESS_KEY
endpoint = $ENDPOINT" | tee "$CREDS" > /dev/null

chmod 600 "$CREDS"

echo "✔ Credentials file created"
else
echo "✔ Existing Credentials file found"
fi
echo

# Create and overwrite systemd mount unit
echo "[Unit]
Description=Cloudflare R2 bucket for Jarvis configuration files mounted using RClone
Requires=network-online.target
After=network-online.target

[Service]
Type=notify
ExecStartPre=/bin/mkdir -p "$MOUNT_POINT"
ExecStart=/usr/bin/rclone mount --allow-other --vfs-cache-mode writes --config "$CREDS" jarvis:jarvis/configs "$MOUNT_POINT"
ExecStop=/bin/fusermount -u "$MOUNT_POINT"
Restart=always
RestartSec=10

[Install]
WantedBy=default.target" | sudo tee "$SYSTEMD_MOUNT" > /dev/null

echo
echo "✔ Successfully systemd mount unit"
echo

# Add the mount entry to /etc/fstab
sudo sed -i 's/#user_allow_other/user_allow_other/' /etc/fuse.conf

# Mount all drives in /etc/fstab
sudo systemctl daemon-reload
sudo systemctl enable "$SYSTEMD_MOUNT_UNIT"
sudo systemctl start "$SYSTEMD_MOUNT_UNIT"

# Allow mount point read-write permission to user "ritik"
sudo chown -R ritik:ritik /mnt
sudo chmod -R u+rwx /mnt

if mount | grep -q "$MOUNT_POINT"; then
    echo
    echo "✔ Cloudflare R2 Storage mounted at $MOUNT_POINT"
else
    echo "⛔ Oops! mount point not working! please check"
fi


# Remove Multipart uploads
# https://community.cloudflare.com/t/cannot-delete-r2-bucket-even-it-empty/422485/5