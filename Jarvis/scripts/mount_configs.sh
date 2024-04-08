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
    echo "✔ S3FS is already installed"
else
    echo "Installing S3FS..."
    sudo apt install s3fs -y
    echo
    echo "✔ S3FS installed successfully"
    echo
fi

# Create s3fs credential file
S3FS_CREDS="$HOME/.passwd-s3fs"

if [ ! -f "$S3FS_CREDS" ]; then
    read -p "Enter the Access Key ID: " ACCESS_KEY_ID
    read -p "Enter the Secret Access Key: " SECRET_ACCESS_KEY

    echo "$ACCESS_KEY_ID:$SECRET_ACCESS_KEY" | tee "$S3FS_CREDS" > /dev/null

    chmod 600 "$S3FS_CREDS"

    echo "✔ S3FS credential file created"
else
    echo "✔ Existing S3FS credential file found"
fi
echo
read -p "Enter the Endpoint: " ENDPOINT

# Check if mount directory exists, create if not
if [ ! -d "$MOUNT_POINT" ]; then
    sudo mkdir -p "$MOUNT_POINT"
fi

FSTAB_ENTRY="jarvis:/configs "$MOUNT_POINT" fuse.s3fs url="$ENDPOINT",passwd_file="$S3FS_CREDS",_netdev,allow_other,dbglevel=info 0 0"

# Remove if entry already exists in /etc/fstab
EXISTING_ENTRY=$(grep " $MOUNT_POINT" /etc/fstab)
if [ -n "$EXISTING_ENTRY" ]; then
    echo
    echo "Removing existing \""$MOUNT_POINT"\" entry found in fstab"
    sudo sed -i "\|^$EXISTING_ENTRY|d" /etc/fstab
fi

# Add the mount entry to /etc/fstab
sudo sed -i 's/#user_allow_other/user_allow_other/' /etc/fuse.conf
echo "$FSTAB_ENTRY" | sudo tee -a /etc/fstab > /dev/null
echo
echo "✔ Successfully created fstab entry"
echo

# Mount all drives in /etc/fstab
sudo mount -a

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