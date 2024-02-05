#!/bin/bash -e

# Check super user permission
if [ $(id -u) -ne 0 ];
then
  echo "⛔ This script needs to run WITH superuser permission!"
  exit 1
fi

echo "⚪ Setting up ftp server"
echo

# Check if vsftpd is installed
if ! dpkg -l | grep vsftpd > /dev/null; then
    # Install vsftpd
    echo "Installing vsftpd server"
    sudo apt install vsftpd -y
else
    echo "vsftpd is already installed"
fi

# Create users for the directory
useradd -m -c "FTP User" -s /usr/sbin/nologin jarvis
echo "jarvis:password" | chpasswd

echo "FTP user created"

chown jarvis:jarvis /home/ritik
chown jarvis:jarvis /mnt/drive1
chmod a-w /mnt/drive1/Public

echo "FTP user granted access to folders"

# Create the vsftpd user config files
echo "jarvis" | tee -a /etc/vsftpd.userlist

# Create the vsftpd config files
cat > /etc/vsftpd.conf <<EOF
listen=YES
listen_port=2100
anonymous_enable=NO
local_enable=YES
write_enable=YES
local_umask=022
dirmessage_enable=YES
use_localtime=YES
xferlog_enable=YES
secure_chroot_dir=/var/run/vsftpd/empty
pam_service_name=vsftpd
rsa_cert_file=/etc/ssl/private/ssl-cert-snakeoil.pem
rsa_private_key_file=/etc/ssl/private/ssl-cert-snakeoil.key
userlist_enable=YES
userlist_file=/etc/vsftpd.userlist
userlist_deny=NO
EOF

echo "vsftpd configuration successful"

# Restart the vsftpd service
service vsftpd restart