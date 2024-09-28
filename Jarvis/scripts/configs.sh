#!/bin/bash -e

printf '\n+%131s+\n\n' | tr ' ' '-'
echo -e "● Setup configurations\n"

BASE_DIR="$HOME/.$JARVIS_HOSTNAME"
CONFIG_REPO="git@github.com:itzzjarvis/configs.git"

echo "→ Init config and log directories"
mkdir -p "$JARVIS_CONFIGS" "$JARVIS_LOGS"
sudo rm -rf "$JARVIS_LOGS"/*

if [ ! -d "$JARVIS_CONFIGS/.git" ]; then
	echo -e "→ Fetch and restore configurations\n"
	git clone "$CONFIG_REPO" "$JARVIS_CONFIGS" || { echo "✕ Failed to fetch configurations"; exit 1; }
	echo
fi

echo "→ Cleanup empty directories"
find "$BASE_DIR" -mindepth 1 -maxdepth 1 -type d -empty -exec rmdir {} +

echo -e "→ Setting up permissions"
sudo chown -R $USER:$USER "$BASE_DIR"
sudo chmod -R 777 "$BASE_DIR"

echo "→ Setting up backup script"
BACKUP_SCRIPT_PATH="$BASE_DIR/scripts/backup.sh"
mkdir -p "$(dirname "$BACKUP_SCRIPT_PATH")"

[ ! -f "$BACKUP_SCRIPT_PATH" ] && cat << EOF > "$BACKUP_SCRIPT_PATH"
#!/bin/bash

cd "$JARVIS_CONFIGS" || exit
git add . && git commit -m "Auto backup - \$(date '+%d %b %Y - %I:%M%p')"

(
    git log --all --pretty=format:"%H" --date=short --since="3 months ago" --before="now" --grep="Sun"
    git log --since="7 days ago" --pretty=format:"%H"
) | sort -u | while read HASH; do
    git cherry-pick "\$HASH" || true
done

git reflog expire --expire=all --all && git gc --aggressive --prune=all
git push origin main --force
EOF
chmod +x "$BACKUP_SCRIPT_PATH"

echo "→ Setting up cron job for backup script"
(crontab -l 2>/dev/null | grep -vF "$BACKUP_SCRIPT_PATH"; echo "30 4 * * * $BACKUP_SCRIPT_PATH") | crontab -


