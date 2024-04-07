#!/bin/bash -e

echo
echo "+-----------------------------------------------------------------------------------------------------------------------------------+"
echo
printf '⚪ Mounting configuration bucket (\e]8;;https://developers.cloudflare.com/r2\e\\Cloudflare R2\e]8;;\e\\) using \e]8;;https://github.com/s3fs-fuse/s3fs-fuse\e\\S3FS-Fuse\e]8;;\e\\\n'
echo

# Check super user permission
if [ $(id -u) -eq 0 ]; then
    echo "⛔ This script needs to run WITHOUT superuser permission"
    exit 1
fi

MOUNT_POINT="/mnt/configs"
SYNC_IGNORE="jellyfin/data/metadata/library|radarr/logs|radarr/Backups|sonarr/logs|sonarr/Backups|bazarr/logs|bazarr/backups|bazarr/cache"

# Check if bucket is already mounted
if mount | grep -q "$MOUNT_POINT"; then
    echo "✔ Config bucket is already mounted at $MOUNT_POINT"
    exit 1
fi

# Install S3FS if not already
if [[ $(which s3fs ) && $(s3fs  --version) ]];
then
    echo "✔ S3FS is already installed."
else
    echo "Installing S3FS..."
    sudo apt install s3fs -y
    echo
    echo "✔ S3FS installed successfully."
    echo
fi

# Create s3fs credential file
S3FS_CREDS="$HOME/.passwd-s3fs"

read -p "Enter the Access Key ID: " ID
read -p "Enter the Secret Access Key: " KEY
read -p "Enter the Endpoint: " ENDPOINT

cat <<EOF > "$S3FS_CREDS"
$ID:$KEY
EOF
chmod 600 "$S3FS_CREDS"

echo "✔ S3FS credential file created."

# Check if mount directory exists, create if not
if [ ! -d "$MOUNT_POINT" ]; then
    sudo mkdir -p "$MOUNT_POINT"
fi

# Mount Cloudflare R2 Storage using s3fs
echo
sudo s3fs jarvis:/configs /mnt/configs -o url="$ENDPOINT" -o passwd_file="$S3FS_CREDS" -o ignore="$SYNC_IGNORE" -o allow_other -o dbglevel=info

# Allow mount point read-write permission to user "ritik"
sudo chown -R ritik $MOUNT_POINT
sudo chmod -R 700 $MOUNT_POINT

$FSTAB_ENTRY="s3fs#jarvis:/configs /mnt/configs fuse.s3fs url=$ENDPOINT,passwd_file=$S3FS_CREDS,ignore=$SYNC_IGNORE,allow_other,dbglevel=info 0 0"

# Remove if entry already exists in /etc/fstab
EXISTING_ENTRY=$(grep "^s3fs#jarvis:/configs" /etc/fstab)
if [ -n "$EXISTING_ENTRY" ]; then
    echo "Removing existing \"s3fs#jarvis:/configs\" entry found in fstab."
    sudo sed -i "\|^$EXISTING_ENTRY|d" /etc/fstab
fi

# Add the mount entry to /etc/fstab
echo "$FSTAB_ENTRY" | sudo tee -a /etc/fstab

echo

if mount | grep -q "$MOUNT_POINT"; then
  echo "✔ Cloudflare R2 Storage mounted at $MOUNT_POINT"
  exit 1
else
  echo "⛔ Oops! mount point not working! please check."
fi