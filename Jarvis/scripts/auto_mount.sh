#!/bin/bash -e

# Check super user permission
if [ $(id -u) -ne 0 ];
then
  echo "⛔ This script needs to run WITH superuser permission"
  exit 1
fi

echo "⚪ Creating auto mount entry for drive in Fstab"
echo

if [[ $(findmnt --fstab --target /media/drive1 -A) ]];
then
  echo "Drive is already mounted!"
  exit 1
fi

DRIVE="/media/drive1"

# Create mount point
sudo mkdir -p $DRIVE

# Show drive details
lsblk -o NAME,FSTYPE,UUID,MOUNTPOINTS

# Input drive uuid and filesystem type
echo
echo "Please find your drive from above table."
read -p "Enter the UUID here: " UUID
read -e -p "Enter the File system type here: " -i "ext4" FS

# Write the entry to fstab
cat << EOF >> /etc/fstab
  UUID=$UUID $DRIVE   $FS    defaults        0       0
EOF

echo
echo "Successfully created fstab entry."

if [[ $(sudo findmnt --verify) == "Success, no errors or warnings detected" ]];
then
  echo "Automounting verified, Rebooting..."
  echo .
  echo .
  echo .
  sudo reboot
else
  echo "⛔ Oops! Automounting not working! please check."
fi
