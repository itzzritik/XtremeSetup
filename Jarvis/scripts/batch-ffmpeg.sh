#!/bin/bash -e

# Check super user permission
if [ $(id -u) -eq 0 ];
then
    echo ⛔ This script needs to run WITHOUT superuser permission!
    exit 1
fi

DIRECTORY="/media/drive1/Public/Movies/Marvel Cinematic Universe"
ALREADY_CONVERTED=()

echo "⚪ Coverting MKV Movies to MP4"
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
for FILE in "$DIRECTORY"/**/*.mkv;
do
    if ! [ -f "${FILE%.*}.mp4" ]
    then
        echo "- Converting $FILE"
        echo
        
        # ffmpeg -v quiet -stats -i "$FILE" -c copy "${FILE%.*}.mp4"
        # Get video duration in frames
        duration=$(ffmpeg -i "$FILE" 2>&1 | sed -n "s/.* Duration: \([^,]*\), start: .*/\1/p")
        fps=$(ffmpeg -i "$FILE" 2>&1 | sed -n "s/.*, \(.*\) tbr.*/\1/p")
        hours=$(echo $duration | cut -d":" -f1)
        minutes=$(echo $duration | cut -d":" -f2)
        seconds=$(echo $duration | cut -d":" -f3)
        FRAMES=$(echo "($hours*3600+$minutes*60+$seconds)*$fps" | bc | cut -d"." -f1)
        
        # Start ffmpeg, use awk to flush the buffer and remove carriage returns
	    ffmpeg -v quiet -i "$FILE" -c copy "${FILE%.*}.mp4" | awk '1;{fflush()}' RS='\r\n'>/logs/ffmpeg &

        # Get ffmpeg Process ID
	    PID=$( ps -ef | grep "ffmpeg" | grep -v "grep" | awk '{print $2}' )
        echo $PID
        # While ffmpeg runs, process the log file for the current frame, display percentage progress
        while ps -p $PID>/dev/null  ; do
            currentframe=$(tail -n 1 /logs/ffmpeg | awk '/frame=/ { print $2 }')
            echo $currentframe
            if [[ -n "$currentframe" ]];
            then
                PROG=$(echo "scale=3; ($currentframe/$FRAMES)*100.0" | bc)
                echo PROGRESS: $PROG
                sleep 1
            fi
        done
        mv "$FILE" "$FILE.bak"
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

