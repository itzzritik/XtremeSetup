#!/bin/bash -e

echo
echo "+-----------------------------------------------------------------------------------------------------------------------------------+"
echo
printf '⚪ Setting up \e]8;;https://developers.cloudflare.com/r2/\e\\Cloudflare R2\e]8;;\e\\\n'
echo

# Check super user permission
if [ $(id -u) -ne 0 ]; then
  echo "⛔ This script needs to run WITH superuser permission!"
  exit 1
fi

# Install RClone if not already
if [[ $(which rclone ) && $(rclone  -v) ]];
then
    echo "✔ RClone is already installed."
else
    echo "Installing RClone..."
    sudo apt install rclone -y
    echo
    echo "✔ RClone installed successfully."
fi

# Check if RClone configuration exists
if [ ! -f "$HOME/.config/rclone/rclone.conf" ]; then
    echo "RClone configuration not found. Setting up config..."
    rclone config
fi

# Check if rclone mount directory exists, create if not
MOUNT_POINT="/mnt/configs"
if [ ! -d "$MOUNT_POINT" ]; then
    mkdir -p "$MOUNT_POINT"
fi

# Mount Cloudflare R2 Storage using rclone
rclone mount cloudflare_r2:jarvis/config "$MOUNT_DIR" --daemon

echo "✔ Cloudflare R2 Storage mounted at $MOUNT_DIR"