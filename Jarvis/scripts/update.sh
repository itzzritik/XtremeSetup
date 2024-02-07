#!/bin/bash -e

echo "+-----------------------------------------------------------------------------------------------------------------------------------+"
echo "|                                                                                                                                   |"
echo "|                                                       UPDATING RASPBERRY PI                                                       |"
echo "|                                                                                                                                   |"
echo "+-----------------------------------------------------------------------------------------------------------------------------------+"
echo

if [ -f /sys/firmware/devicetree/base/model ]; then
    DEVICE=$(tr -d '\0' </sys/firmware/devicetree/base/model)
else
    DEVICE="System"
fi

echo "⚪ Updating $DEVICE..."
echo

# Check super user permission
if [ $(id -u) -ne 0 ]; then
  echo ⛔ This script needs to run WITH superuser permission!
  exit 1
fi

# Check the last modified date of the package lists
last_update=$(stat -c %Y /var/lib/apt/periodic/update-success-stamp)

# Get the current date
current_time=$(date +%s)

# Calculate the difference in days
time_difference=$(echo "($current_time - $last_update) / (60 * 60 * 24)" | bc)

# Define how many days ago is considered "recent"
threshold=1

if [ $time_difference -gt $threshold ]; then
    echo ""
    echo ""
    sudo apt update -y
    sudo apt upgrade -y
    sudo apt autoremove -y
    echo ""
    echo ""
else
    echo "✔ System already up to date"
fi