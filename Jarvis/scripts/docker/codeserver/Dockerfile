FROM codercom/code-server

RUN code-server --install-extension redhat.vscode-yaml
RUN code-server --install-extension foxundermoon.shell-format
RUN code-server --install-extension eamodio.gitlens
RUN code-server --install-extension seatonjiang.gitmoji-vscode
RUN code-server --install-extension equinusocio.vsc-material-theme
RUN code-server --install-extension pkief.material-icon-theme

RUN mkdir -p /home/coder/.local/share/code-server/User
RUN echo '{ \
        "workbench.colorTheme": "Material Theme Ocean High Contrast" \
        "workbench.iconTheme": "material-icon-theme" \
    }' > /home/coder/.local/share/code-server/User/settings.json