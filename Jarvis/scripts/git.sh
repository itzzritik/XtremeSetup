#!/bin/bash -e

printf '\n+%131s+\n\n' | tr ' ' '-'
echo -e "● Setting up git environment\n"

REQUIRED_VARS=(
	"JARVIS_HOSTNAME"
	"JARVIS_EMAIL"
	"JARVIS_GITHUB_TOKEN_SSH"
)
for VAR in "${REQUIRED_VARS[@]}"; do [ -z "${!VAR}" ] && echo "✕ Env variable \"$VAR\" not set!" && exit 1; done

KEY_PATH="$HOME/.ssh/id_ed25519"

git config --global user.name "$(echo "${JARVIS_HOSTNAME^}")"
git config --global user.email "$JARVIS_EMAIL"

echo "✔ Git user name: $(git config --global user.name)"
echo "✔ Git user email: $(git config --global user.email)"

git config --global init.defaultBranch main

if [ -f "$KEY_PATH" ] && [ -f "$KEY_PATH.pub" ]; then
	echo "✔ SSH keys already exist at \"$KEY_PATH.pub\""
else
	echo "→ Generating new SSH key at \"$KEY_PATH\""
	ssh-keygen -t ed25519 -C "$JARVIS_EMAIL" -f "$KEY_PATH" -N ""
	eval "$(ssh-agent -s)"
	ssh-add "$KEY_PATH"

	echo -e "\n→ Deleating existing key on your GitHub"
	EXISTING_KEY_ID=$(curl -s -H "Authorization: token $JARVIS_GITHUB_TOKEN_SSH" https://api.github.com/user/keys | jq -r ".[] | select(.title==\"$JARVIS_HOSTNAME\") | .id")
	[ -n "$EXISTING_KEY_ID" ] && curl -s -X DELETE -H "Authorization: token $JARVIS_GITHUB_TOKEN_SSH" https://api.github.com/user/keys/$EXISTING_KEY_ID

	echo -e "\n→ Uploading new SSH key to your GitHub"
	RESPONSE=$(curl -s -X POST https://api.github.com/user/keys \
		-H "Authorization: token $JARVIS_GITHUB_TOKEN_SSH" -H "Content-Type: application/json" \
		-d "{\"title\":\"$JARVIS_HOSTNAME\",\"key\":\"$(< "$KEY_PATH.pub")\"}")

	if ! echo "$RESPONSE" | grep -q '"key":'; then
		echo -e "✕ Failed to add SSH key to GitHub, Response:\n"
		echo "$RESPONSE"; exit 1
	fi

	echo "✔ SSH key added to GitHub successfully!"
fi

echo "✔ Git environment setup successfully"