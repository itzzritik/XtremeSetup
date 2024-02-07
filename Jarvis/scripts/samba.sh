#!/bin/bash -e

echo
echo "+-----------------------------------------------------------------------------------------------------------------------------------+"
echo
echo "⚪ Setting up samba server"
echo

# Check super user permission
if [ $(id -u) -ne 0 ]; then
  echo "⛔ This script needs to run WITH superuser permission!"
  exit 1
fi

# Check if samba is already installed
if [[ $(which samba) && $(samba --version) ]];
then
  echo "✔ Samba is already setup!"
  exit 0
fi

# Install samba packages
sudo apt install samba samba-common-bin

cat << EOF >> /etc/samba/smb.conf

[Jarvis]
  comment = Jarvis
  path = /home/ritik
  writeable = Yes
  create mask = 0777
  directory mask = 0777
  public = no

[JarvisCloud]
  comment = Jarvis Cloud
  path = /mnt/drive1
  writeable = Yes
  create mask = 0777
  directory mask = 0777
  public = no

[Media]
  comment = Jarvis Media Cloud
  path = /mnt/drive1/Public
  read only = yes
  writeable = No
  guest ok = yes
  public = yes

EOF

echo
echo Please create a password for user ritik:
sudo smbpasswd -a ritik
sudo systemctl restart smbd
echo
echo "✔ Successfully setup samba server."