#!/bin/bash -e

echo
echo "+-----------------------------------------------------------------------------------------------------------------------------------+"
echo
echo "⚪ Automount drives using"
echo

# Check super user permission
if [ $(id -u) -eq 0 ]; then
    echo "⛔ This script needs to run WITHOUT superuser permission"
    exit 1
fi

if [ -f /etc/usbmount/usbmount.conf ]; then
    echo "✔ Drive is already mounted!"
    exit 1
fi

packages=("usbmount" "ntfs-3g")

for package in "${packages[@]}"; do
    if dpkg -s "$package" >/dev/null 2>&1; then
        echo "✔ $package is already installed."
    else
        echo "Installing $package..."
        sudo apt install -y "$package"
    fi
done

sudo sed -i 's/FILESYSTEMS="vfat ext2 ext3 ext4 hfsplus"/FILESYSTEMS="vfat ext2 ext3 ext4 hfsplus ntfs ntfs-3g"/' /etc/usbmount/usbmount.conf
sudo systemctl restart usbmount

echo "✔ Drive mounted succesfully"