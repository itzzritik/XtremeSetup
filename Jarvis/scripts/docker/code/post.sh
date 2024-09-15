printf '\n+%131s+\n\n' | tr ' ' '-'
echo -e "● Post script for ${JARVIS_CONTAINER_NAME}\n"

EXTENSION_LIST=(
	"redhat.vscode-yaml"
	"foxundermoon.shell-format"
	"eamodio.gitlens"
	"seatonjiang.gitmoji-vscode"
	"pkief.material-icon-theme"
)

for EXTENSION in "${EXTENSION_LIST[@]}"; do
	echo "✔ Installing $EXTENSION extension"
	docker exec "${JARVIS_CONTAINER_NAME}" code-server --install-extension "$EXTENSION" --force &
done

echo "✔ Applying settings"
SETTINGS=$(
	cat <<EOF
{
    "workbench.colorTheme": "Material Theme Ocean High Contrast",
    "workbench.iconTheme": "material-icon-theme"
}
EOF
)
docker exec "${JARVIS_CONTAINER_NAME}" bash -c "mkdir -p ~/.local/share/code-server/User && echo '$SETTINGS' > ~/.local/share/code-server/User/settings.json" &

wait
