#!/bin/bash -e

printf '\n+%131s+\n' | tr ' ' '-'
echo "|                                                                                                                                   |"
echo "|                                                      DOCKER DEPLOYMENT LOGS                                                       |"
echo "|                                                                                                                                   |"
printf '+%131s+\n\n' | tr ' ' '-'

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
FAIL_COUNT=$(find "$SCRIPT_DIR" -type f -name 'deploy.log' | wc -l)

echo -e "\n● $FAIL_COUNT apps failed with error/warning, Please check logs"

for LOG_FILE in $(find "$SCRIPT_DIR" -type f -name 'deploy.log'); do
	NAME=$(basename "$(dirname "$LOG_FILE")")
	TITLE_NAME="${NAME^}"
	printf '\n→ \e]8;;%s\a%s\e]8;;\a\n\n' "" "$TITLE_NAME"
	cat "$LOG_FILE"
	rm -f "$LOG_FILE"
	printf '\n+%131s+\n' | tr ' ' '-'
done
