#!/bin/bash -e

printf '\n+%131s+\n\n' | tr ' ' '-'
echo -e "● Setup configurations\n"

BASE_DIR="$HOME/.$JARVIS_HOSTNAME"
CONFIG_REPO="git@github.com:itzzjarvis/configs.git"
SUDOERS_ENTRY="ritik ALL=(ALL) NOPASSWD: /bin/chmod"

echo "→ Enable passwordless sudo for chmod"
sudo grep -Fxq "$SUDOERS_ENTRY" "/etc/sudoers" || echo "$SUDOERS_ENTRY" | sudo tee -a "/etc/sudoers" > /dev/null 2>&1

echo "→ Init config and log directories"
mkdir -p "$JARVIS_CONFIGS" "$JARVIS_LOGS"

if [ ! -d "$JARVIS_CONFIGS/.git" ]; then
	echo -e "→ Fetch and restore configurations\n"
	git clone "$CONFIG_REPO" "$JARVIS_CONFIGS" || { echo "✕ Failed to fetch configurations"; exit 1; }
	echo
fi

echo "→ Cleanup empty directories"
find "$BASE_DIR" -mindepth 1 -maxdepth 1 -type d -empty -exec rmdir {} +

echo "→ Setting up backup script"
BACKUP_SCRIPT_PATH="$BASE_DIR/scripts/backup.sh"
mkdir -p "$(dirname "$BACKUP_SCRIPT_PATH")"

cat << EOF > "$BACKUP_SCRIPT_PATH"
#!/bin/bash

YESTERDAY=\$(date -d "yesterday" '+%d-%m-%Y')
LOG_FILE="$JARVIS_LOGS/backup/\$YESTERDAY.log"
mkdir -p "\$(dirname "\$LOG_FILE")"

exec > >(tee -a "\$LOG_FILE") 2>&1
echo -e "→ Backup started at \$(date '+%d %b %Y - %I:%M%p')"

echo -e "→ Stopping docker containers"
docker stop \$(docker ps -q) > /dev/null 2>&1

sleep 5
sudo chmod -R 777 "$JARVIS_CONFIGS"
cd "$JARVIS_CONFIGS" || exit

git branch -D "\$YESTERDAY" 2>/dev/null
git add .
git branch "\$YESTERDAY" \$(echo "🤖 Auto backup" | git commit-tree HEAD^{tree})
git checkout "\$YESTERDAY"
git branch -D main
git checkout -b main

BRANCHES_TO_KEEP=(\$(
    for i in {0..6}; do date -d "\$i days ago" '+%d-%m-%Y'; done
    for i in {0..4}; do date -d "last-sunday -\$i week" '+%d-%m-%Y'; done
))

git branch | grep -v "main" | while read BRANCH; do
    [[ " \${BRANCHES_TO_KEEP[*]} " =~ " \${BRANCH} " ]] || git branch -D "\$BRANCH"
done

git gc --aggressive --prune=all
git push origin --all --prune --force

echo -e "→ Starting docker containers"
docker start \$(docker ps -aq) > /dev/null 2>&1
echo -e "→ Backup completed at \$(date '+%d %b %Y - %I:%M%p')"
EOF

echo "→ Setting up cron job for backup script"
(crontab -l 2>/dev/null | grep -vF "$BACKUP_SCRIPT_PATH"; echo "30 4 * * * $BACKUP_SCRIPT_PATH") | crontab -

echo -e "→ Setting up permissions"
sudo chown -R $USER:$USER "$BASE_DIR"
sudo chmod -R 777 "$BASE_DIR"
chmod +x "$BACKUP_SCRIPT_PATH"