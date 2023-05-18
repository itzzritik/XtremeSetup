#!/bin/bash -e

# Check super user permission
if [ $(id -u) -eq 0 ];
then
    echo ⛔ This script needs to run WITHOUT superuser permission!
    exit 1
fi

ROOT="/media/drive1"
DIRECTORY="$ROOT/Public/Movies/Bollywood"
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

function SHOW_PROGRESS_BAR {
    local current="$1"
    local total="$2"
    local bar_size=100
    local bar_char_done="█"
    local bar_char_todo="░"
    local bar_percentage_scale=2
    local percent=$(bc <<< "scale=$bar_percentage_scale; 100 * $current / $total" )
    
    # The number of done and todo characters
    done=$(bc <<< "scale=0; $bar_size * $percent / 100" )
    todo=$(bc <<< "scale=0; $bar_size - $done" )

    # build the done and todo sub-bars
    done_sub_bar=$(printf "%-${done}s" | sed "s/ /$bar_char_done/g")
    todo_sub_bar=$(printf "%-${todo}s" | sed "s/ /$bar_char_todo/g")

    # output the bar
    printf "${done_sub_bar}${todo_sub_bar} ${percent}%%"
}
// ◠◡◠◡◠◡◠◡◠◡◠◡◠◡◠◡◠◡◠◡◠◡◠◡◠◡◠◡◠◡◠◡◠◡◠◡◠◡◠◡◠◡◠◡◠◡◠◡◠◡◠◡◠◡◠◡◠◡◠◡●●⦿➒❥▻
function SHOW_PROGRESS_BAR {
    local current="$1"
    local total="$2"
    local bar_size=100
    local bar_char_done="█"
    local bar_char_todo="░"
    local bar_percentage_scale=2
    local percent=$(bc <<< "scale=$bar_percentage_scale; 100 * $current / $total" )
    
    # The number of done and todo characters
    done=$(bc <<< "scale=0; $bar_size * $percent / 100" )
    todo=$(bc <<< "scale=0; $bar_size - $done" )

    # build the done and todo sub-bars
    done_sub_bar=$(printf "%-${done}s" | sed "s/ /$bar_char_done/g")
    todo_sub_bar=$(printf "%-${todo}s" | sed "s/ /$bar_char_todo/g")

    # output the bar
    printf "${done_sub_bar}${todo_sub_bar} ${percent}%%"
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

        # Convert movie using ffmpeg
        ffmpeg -i "$INPUT" -c copy "$OUTPUT" >/dev/null 2>&1 &
        pid=$!
        while kill -0 $pid >/dev/null 2>&1;
        do
            PROGRESS_FILE_SIZE=$(stat -c "%s" "$OUTPUT" 2>/dev/null || echo 0)
            SHOW_PROGRESS_BAR $PROGRESS_FILE_SIZE $INPUT_FILE_SIZE
            sleep 0.5
            printf "\r"
        done
        
        #Original file to backup file
        FILENAME=$(basename -- "$FILE")
        mv "$FILE" "$ROOT/Downloads/Backup/$FILENAME.bak"

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

