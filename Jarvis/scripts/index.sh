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

if [ $(id -u) -eq 0 ];
then
   echo "⛔ Please run this script WITHOUT superuser permission!"
   echo
   echo "+-----------------------------------------------------------------------------------------------------------------------------------+"
   echo && exit 1
fi

SCRIPT_DIR="$( cd "$( dirname "$(readlink -f "$0")" )" && pwd )"
sudo bash $SCRIPT_DIR/update.sh

echo
echo "+-----------------------------------------------------------------------------------------------------------------------------------+"
echo "|                                                                                                                                   |"
echo "|                                                         SETTING UP JARVIS                                                         |"
echo "|                                                                                                                                   |"
echo "+-----------------------------------------------------------------------------------------------------------------------------------+"
echo

export JARVIS_DRIVE_ROOT="/mnt/drive1"
export JARVIS_CONFIG_ROOT="/mnt/configs"

bash $SCRIPT_DIR/git.sh
bash $SCRIPT_DIR/timezone.sh
bash $SCRIPT_DIR/hostname.sh
bash $SCRIPT_DIR/ssh.sh
bash $SCRIPT_DIR/automount.sh
bash $SCRIPT_DIR/docker/docker.sh

echo
echo "+-----------------------------------------------------------------------------------------------------------------------------------+"
echo