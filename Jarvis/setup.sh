#!/bin/bash -e

printf "\033c"
echo
echo "+-----------------------------------------------------------------------------------------------------------------------------------+"
echo
echo '______________/\\\\\\\\\\\_____/\\\\\\\\\_________/\\\\\\\\\______/\\\________/\\\__/\\\\\\\\\\\_____/\\\\\\\\\\\___________'
echo ' _____________\/////\\\///____/\\\\\\\\\\\\\_____/\\\///////\\\___\/\\\_______\/\\\_\/////\\\///____/\\\/////////\\\_________'
echo '  _________________\/\\\______/\\\/////////\\\___\/\\\_____\/\\\___\//\\\______/\\\______\/\\\______\//\\\______\///__________'
echo '   _________________\/\\\_____\/\\\_______\/\\\___\/\\\\\\\\\\\/_____\//\\\____/\\\_______\/\\\_______\////\\\_________________'
echo '    _________________\/\\\_____\/\\\\\\\\\\\\\\\___\/\\\//////\\\______\//\\\__/\\\________\/\\\__________\////\\\______________'
echo '     _________________\/\\\_____\/\\\/////////\\\___\/\\\____\//\\\______\//\\\/\\\_________\/\\\_____________\////\\\___________'
echo '      __________/\\\___\/\\\_____\/\\\_______\/\\\___\/\\\_____\//\\\______\//\\\\\__________\/\\\______/\\\______\//\\\__________'
echo '       _________\//\\\\\\\\\______\/\\\_______\/\\\___\/\\\______\//\\\______\//\\\________/\\\\\\\\\\\_\///\\\\\\\\\\\/___________'
echo '        __________\/////////_______\///________\///____\///________\///________\///________\///////////____\///////////_____________'
echo
echo

# Check super user permission
if [ $(id -u) -eq 0 ];
then
   echo "⛔ Please run this script WITHOUT superuser permission!"
   echo
   echo "+-----------------------------------------------------------------------------------------------------------------------------------+"
   echo
   exit 1
fi

echo "+-----------------------------------------------------------------------------------------------------------------------------------+"
echo "|                                                                                                                                   |"
echo "|                                                       UPDATING RASPBERRY PI                                                       |"
echo "|                                                                                                                                   |"
echo "+-----------------------------------------------------------------------------------------------------------------------------------+"
echo
sudo apt update && sudo apt upgrade -y
sudo apt autoremove
echo
echo "+-----------------------------------------------------------------------------------------------------------------------------------+"
echo "|                                                                                                                                   |"
echo "|                                                         SETTING UP JARVIS                                                         |"
echo "|                                                                                                                                   |"
echo "+-----------------------------------------------------------------------------------------------------------------------------------+"
echo
bash ./scripts/create_dirs.sh
echo
echo "+-----------------------------------------------------------------------------------------------------------------------------------+"
echo
bash ./scripts/ssh.sh
echo
echo "+-----------------------------------------------------------------------------------------------------------------------------------+"
echo
sudo bash ./scripts/auto_mount.sh
echo
echo "+-----------------------------------------------------------------------------------------------------------------------------------+"
echo
sudo bash ./scripts/static_ip.sh
echo
echo "+-----------------------------------------------------------------------------------------------------------------------------------+"
echo
sudo bash ./scripts/docker/docker_setup.sh
echo
echo "+-----------------------------------------------------------------------------------------------------------------------------------+"
echo
bash ./scripts/docker/homebridge/deploy.sh
echo
echo "+-----------------------------------------------------------------------------------------------------------------------------------+"
echo
bash ./scripts/docker/media-server/deploy.sh
echo
echo "+-----------------------------------------------------------------------------------------------------------------------------------+"
echo
sudo bash ./scripts/samba.sh
echo
echo "+-----------------------------------------------------------------------------------------------------------------------------------+"
echo

