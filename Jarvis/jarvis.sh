#!/bin/bash

JarvisLocation="~/.jarvis"
RepoName="XtremeSetup"
RepoUrl="https://github.com/itzzritik/$RepoName.git"

# Create a hidden directory
mkdir -p "$JarvisLocation"
cd "$JarvisLocation" || { echo "Error: Unable to change to the hidden jarvis directory."; exit 1; }

# Clone the Git repository
git clone "$RepoUrl" || { echo "Error: Unable to clone the repository."; exit 1; }

# Change to the repository directory
cd "$RepoName" || { echo "Error: Unable to change to the repository directory."; exit 1; }

# Run the script inside the repository
bash "$JarvisLocation/$RepoName/Jarvis/scripts/index.sh" || { echo "Error: Script execution failed."; exit 1; }

# delete the hidden dir after script completion
rm -rf "$JarvisLocation"
