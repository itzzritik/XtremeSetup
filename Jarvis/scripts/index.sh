#!/bin/bash -e

printf "\033c"
printf '\n+%131s+\n\n' | tr ' ' '-'
cat << 'EOF'
______________/\\\\\\\\\\\_____/\\\\\\\\\_________/\\\\\\\\\______/\\\________/\\\__/\\\\\\\\\\\_____/\\\\\\\\\\\___________
 _____________\/////\\\///____/\\\\\\\\\\\\\_____/\\\///////\\\___\/\\\_______\/\\\_\/////\\\///____/\\\/////////\\\_________
  _________________\/\\\______/\\\/////////\\\___\/\\\_____\/\\\___\//\\\______/\\\______\/\\\______\//\\\______\///__________
   _________________\/\\\_____\/\\\_______\/\\\___\/\\\\\\\\\\\/_____\//\\\____/\\\_______\/\\\_______\////\\\_________________
    _________________\/\\\_____\/\\\\\\\\\\\\\\\___\/\\\//////\\\______\//\\\__/\\\________\/\\\__________\////\\\______________
     _________________\/\\\_____\/\\\/////////\\\___\/\\\____\//\\\______\//\\\/\\\_________\/\\\_____________\////\\\___________
      __________/\\\___\/\\\_____\/\\\_______\/\\\___\/\\\_____\//\\\______\//\\\\\__________\/\\\______/\\\______\//\\\__________
       _________\//\\\\\\\\\______\/\\\_______\/\\\___\/\\\______\//\\\______\//\\\________/\\\\\\\\\\\_\///\\\\\\\\\\\/___________
        __________\/////////_______\///________\///____\///________\///________\///________\///////////____\///////////_____________


EOF

if [ $(id -u) -eq 0 ];
then
   echo "✕ Please run this script WITHOUT superuser permission!"
   printf '\n+%131s+\n\n' | tr ' ' '-'
   exit 1
fi

ORIGINAL_ENV=$(export -p)
SCRIPT_DIR="$( cd "$( dirname "$(readlink -f "$0")" )" && pwd )"
sudo bash $SCRIPT_DIR/update.sh

printf '\n+%131s+\n' | tr ' ' '-'
echo "|                                                                                                                                   |"
echo "|                                                         SETTING UP JARVIS                                                         |"
echo "|                                                                                                                                   |"
printf '+%131s+\n\n' | tr ' ' '-'

source $SCRIPT_DIR/environment.sh
bash $SCRIPT_DIR/timezone.sh
bash $SCRIPT_DIR/git.sh
bash $SCRIPT_DIR/configs.sh
bash $SCRIPT_DIR/bluetooth.sh
bash $SCRIPT_DIR/hostname.sh
bash $SCRIPT_DIR/static_ip.sh
bash $SCRIPT_DIR/ssh.sh
bash $SCRIPT_DIR/automount.sh
bash $SCRIPT_DIR/docker/docker.sh

eval "$ORIGINAL_ENV"
printf '\n+%131s+\n\n' | tr ' ' '-'