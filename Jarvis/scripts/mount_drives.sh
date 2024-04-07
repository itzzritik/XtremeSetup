#!/bin/bash -e

echo
echo "+-----------------------------------------------------------------------------------------------------------------------------------+"
echo
echo "⚪ Creating auto mount entry for drive in Fstab"
echo

# Check super user permission
if [ $(id -u) -eq 0 ]; then
    echo "⛔ This script needs to run WITHOUT superuser permission"
    exit 1
fi

if dpkg -l | grep -q "ntfs-3g"; then
    echo "✔ NTFS support is already installed."
else
    echo "Installing NTFS support..."
    apt-get install ntfs-3g -y
fi

MOUNT_POINT="/mnt/drive1"
DRIVE="/dev/sda1"

if [[ $(findmnt --fstab --target $MOUNT_POINT -A) ]];
then
  echo "✔ Drive is already mounted!"
  exit 1
fi

# Create the mount point if it doesn't exist
if [ ! -d "$MOUNT_POINT" ]; then
    mkdir $MOUNT_POINT
fi

# Get the UUID of the drive
UUID=$(blkid -s UUID -o value $DRIVE)

# Check if the drive is available
if [ -z "$UUID" ]; then
    echo "Drive not found."
    exit 1
fi

# Add the mount entry to /etc/fstab
echo "UUID=$UUID $MOUNT_POINT   ext4    defaults        0       0" | sudo tee -a /etc/fstab
echo
echo "✔ Successfully created fstab entry."

# Mount all drives in /etc/fstab
systemctl daemon-reload
sudo mount -a

# Allow mount point read-write permission to user "ritik"
sudo chown -R ritik $MOUNT_POINT
sudo chmod -R 700 $MOUNT_POINT

if [[ $(sudo findmnt --fstab --target $MOUNT_POINT -A) ]]; then
  echo "✔ Drive mounted succesfully"
  exit 1
else
  echo "⛔ Oops! Automounting not working! please check."
fi