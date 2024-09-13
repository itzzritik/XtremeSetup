#!/bin/bash -e

printf '\n+%131s+\n\n' | tr ' ' '-'
echo -e "● Initialize bluetooth\n"

if [ $(id -u) -eq 0 ]; then
  echo "✕ This script needs to run WITHOUT superuser permission" && exit 1
fi

if ! dpkg -l | grep -qw bluez; then
  sudo apt install bluez -y
  echo -e "\n✔ BlueZ installed successfully"
fi

if systemctl is-active --quiet bluetooth; then echo "✔ Bluetooth service is active"; exit 0; fi

echo "→ Enabling bluetooth service"
systemctl enable bluetooth
systemctl start bluetooth

if systemctl is-active --quiet bluetooth; then echo "✔ Bluetooth service is active"; exit 0; fi

echo -e "\n✕ Bluetooth service is not running, attempting to restart"
systemctl restart bluetooth

echo "→ Power cycling bluetooth hardware"
hciconfig hci0 down
hciconfig hci0 up

echo "✔ Bluetooth initialized successfully"