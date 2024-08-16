#!/bin/bash -e

printf '\n+%131s+\n\n' | tr ' ' '-'
echo "⚪ Setting up ftp server"
echo

# Check super user permission
if [ $(id -u) -ne 0 ]; then
  echo "⛔ This script needs to run WITH superuser permission!"
  exit 1
fi

# Install vsftpd
if ! dpkg -l | grep vsftpd > /dev/null; then
    echo "Installing vsftpd server..."
    sudo apt install vsftpd -y
else
    echo "✔ vsftpd is already installed"
fi

# Create users for the directory
sudo useradd -m ftpuser -s /usr/sbin/nologin
echo "ftpuser:password" | sudo chpasswd

echo "FTP user created"

sudo chown ftpuser:ftpuser /home/ritik
sudo chown ftpuser:ftpuser /mnt/drive1
sudo chmod a-w /mnt/drive1/Public

echo "FTP user granted access to folders"

# Create the vsftpd user config files
echo "ftpuser" | tee -a /etc/vsftpd.userlist

# Create the vsftpd config files
sudo sh -c 'echo "
anonymous_enable=NO
local_enable=YES
write_enable=YES
chroot_local_user=YES
local_root=/home/$USER
force_dot_files=YES
pasv_min_port=40000
pasv_max_port=50000
user_sub_token=$USER
" > /etc/vsftpd.conf'


# Restart the vsftpd service
sudo systemctl restart vsftpd

echo "✔vsftpd configuration successful"