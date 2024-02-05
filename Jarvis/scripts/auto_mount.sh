#!/bin/bash -e

echo "⚪ Creating auto mount entry for drive in Fstab"
echo

# Check super user permission
if [ $(id -u) -ne 0 ]; then
  echo "⛔ This script needs to run WITH superuser permission!"
  exit 1
fi

MOUNT_POINT="/mnt/drive1"

if [[ $(findmnt --fstab --target $MOUNT_POINT -A) ]];
then
  echo "✔ Drive is already mounted!"
  exit 1
fi

# Create the mount point if it doesn't exist
if [ ! -d "$MOUNT_POINT" ]; then
    sudo mkdir $MOUNT_POINT
fi

# Get the UUID of the drive
UUID=$(blkid -s UUID -o value $DRIVE)

# Check if the drive is available
if [ -z "$UUID" ]; then
    echo "Drive not found."
    exit 1
fi

# Add the mount to /etc/fstab
echo "UUID=$UUID $MOUNT_POINT auto defaults,nofail 0 0" | sudo tee -a /etc/fstab
echo
echo "✔ Successfully created fstab entry."

# Mount all drives in /etc/fstab
sudo mount -a

if [[ $(findmnt --fstab --target $MOUNT_POINT -A) ]]; then
  echo "✔ Drive mounted succesfully"
  exit 1
else
  echo "⛔ Oops! Automounting not working! please check."
fi