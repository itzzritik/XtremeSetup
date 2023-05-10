#!/bin/bash -e

# Check super user permission
if [ $(id -u) -eq 0 ];
then
    echo ⛔ This script needs to run WITHOUT superuser permission!
    exit 1
fi

DIRECTORY="/media/drive1/Downloads/Backup"
ALREADY_CONVERTED=()

echo "⚪ Coverting MKV Movies to MP4"
echo
# Install pv if not installed already
if ! [[ $(which pv) && $(pv --version) ]];
then
    echo "⛔ Package \"pv\" not found, Installing..."
    echo
    sudo apt install pv -y
    echo
fi
echo
echo "→ Scanning for Movies in directory ($DIRECTORY)"

shopt -s globstar nocaseglob nocasematch  # enable ** and globs case-insensitivity

echo
echo "→ Discovered the following movies in MKV Format:"
echo
for FILE in "$DIRECTORY"/**/*.mkv;
do
    if ! [ -f "${FILE%.*}.mp4" ]
    then
        echo "- $FILE"
    fi
done
echo
echo "→ Converting the discovered movies"
echo

progressbar() {
  local width=50
  local percent=$1
  local progress=$(( width * percent / 100 ))

  # Set color codes
  local color_complete="\e[92m"
  local color_incomplete="\e[37m"
  local color_reset="\e[0m"

  # Print progress bar
  printf "\r"
  printf "${color_complete}$(printf '█%.0s' $(seq 1 "$progress"))${color_incomplete}$(printf ' %.0s' $(seq 1 "$((width-progress))"))${color_reset}"
  printf " %3d%%" "$percent"
}

for FILE in "$DIRECTORY"/**/*.mkv;
do
    if ! [ -f "${FILE%.*}.mp4" ]
    then
        echo "- Converting $FILE"
        echo

        INPUT="$FILE"
        OUTPUT="${FILE%.*}.mp4"
        INPUT_FILE_SIZE=$(du -b "$INPUT" | awk '{print $1}')

        ffmpeg -i "$INPUT" -c copy "$OUTPUT" >/dev/null 2>&1 &
        pid=$!  # Get the PID of the ffmpeg process
        progress=0
        while kill -0 $pid >/dev/null 2>&1;
        do
            PROGRESS_FILE_SIZE=$(stat -c "%s" "$OUTPUT" 2>/dev/null || echo 0)
            PROGRESS=$(echo "($PROGRESS_FILE_SIZE * 100) / $INPUT_FILE_SIZE" | bc)
            progressbar "$PROGRESS"
            sleep 0.5
        done
        
        # Move original file to backup
        # mv "$FILE" "$FILE.bak"
        echo
        echo "✔ Movie converted successfully"
        echo
    else
        ALREADY_CONVERTED+=("$FILE")
    fi
done
echo
echo
echo "✔ All Movies Converted Successfully"
echo

if (( ${#ALREADY_CONVERTED[@]} )); then
    echo "⛔ List of movies ignored as they were already converted:"
    echo
    for FILE in "${ALREADY_CONVERTED[@]}"
    do
        echo "- $FILE"
    done
fi

