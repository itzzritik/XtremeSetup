#!/bin/bash -e

echo -e "\n\n● Post script for ${JARVIS_CONTAINER_NAME}\n"

# echo "→ Waiting for ${JARVIS_CONTAINER_NAME}"
# TIMEOUT=10; ELAPSED=0
# until docker exec "${JARVIS_CONTAINER_NAME}" pg_isready -U "${JARVIS_ADMIN_USERNAME}" >/dev/null 2>&1 || [ "$ELAPSED" -ge "$TIMEOUT" ]; do
#     sleep 1; ((ELAPSED++))
# done || { echo "✕ Container did not come up within $TIMEOUT seconds"; exit 1; }

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