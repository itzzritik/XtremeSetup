printf '\n+%131s+\n\n' | tr ' ' '-'
echo -e "● Post script for ${JARVIS_CONTAINER_NAME}\n"

echo -e "→ Installing extensions\n"
EXTENSION_LIST=(
	"redhat.vscode-yaml"
	"foxundermoon.shell-format"
	"eamodio.gitlens"
	"seatonjiang.gitmoji-vscode"
	"equinusocio.vsc-material-theme"
	"pkief.material-icon-theme"
)

for EXTENSION in "${EXTENSION_LIST[@]}"; do
	docker exec "${JARVIS_CONTAINER_NAME}" code-server --install-extension "$EXTENSION" --force &
done

wait

echo -e "\n✔ Applying settings"
CONFIG_DIR="/home/coder/.local/share/code-server/User"
SETTINGS=$(
	cat <<EOF
{
    "workbench.colorTheme": "Material Theme Ocean High Contrast",
    "workbench.iconTheme": "material-icon-theme"
}
EOF
)
docker exec "${JARVIS_CONTAINER_NAME}" bash -c "mkdir -p '$CONFIG_DIR'; echo '$SETTINGS' > $CONFIG_DIR/settings.json"

echo "✔ Restarting container"
docker restart "${JARVIS_CONTAINER_NAME}" >/dev/null 2>&1 &