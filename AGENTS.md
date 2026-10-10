# Agent Rules

These rules apply to the Ansible projects in this repo: `CodingServer/` (both coding
servers: the Oracle VM and the Proxmox code LXC) and `Proxmox/` (the Proxmox host and
its other LXCs). Other directories like `Jarvis/`, `Windows/` and `Mac/` are not Ansible.

Every Ansible run starts from the Mac.

## Iterating on an Ansible change

1. Apply manually on the target host, verify it works.
2. Port the working change into the playbook.
3. Run only the touched task:
   - `CodingServer/`: `bash CodingServer/index.sh <oracle|proxmox> <task>...`, where
     `<task>` is a task file name without its folder (e.g. `caddy`, `kernel`, `guest`).
   - `Proxmox/`: comment out unrelated entries in the `Proxmox/main.yml` loops, run
     `ansible-playbook -i Proxmox/inventory.ini Proxmox/main.yml`, then revert the comments.
4. Confirm the touched task reports `ok` (idempotent against the manual fix).

Don't re-run the full playbook to iterate.

## Conventions

- Idempotent re-runs must report `changed=0` for touched services.
- Ansible tasks are additive only: they describe the desired steady state.
  Never add tasks that exist purely to clean up something (e.g. `state: absent`,
  `docker rm -f`, "Remove Legacy X"). Cleanup is a one-time manual step on the
  host; the playbook should reflect the world afterward, not the migration path.
- Patch source files via `blockinfile` with named markers, not `replace` regex.
  VS Code web's minified files are the one exception.
- New task files must mirror the structure and style of their siblings (vars layout,
  task naming `'{{ app_name | upper }}: ...'`, ordering, indentation, etc).
- `CodingServer/`: shared work goes in `tasks/common/`, machine-only work in
  `tasks/oracle/` or `tasks/proxmox/`, per-machine values in `host_vars/`, and retired
  tasks in `tasks/archive/`.
- `CodingServer/`: `~/.jarvis/configs/<app>` holds only state Ansible can't recreate, since it
  gets backed up. Anything Ansible can recreate (servers, source, builds, generated config,
  Doppler env files) goes in `~/.jarvis/apps/<app>`.
- `CodingServer/`: full module names (`ansible.builtin.copy`, not `copy`), facts only via
  `ansible_facts.*`, and `ansible-lint` (run inside `CodingServer/`) must pass.
- Languages: Ansible YAML for setup and config, stdlib-only Python for any logic, Bash only
  for thin entry points and wrappers. Use another language only where the runtime forces it
  (browser JS/CSS, code loaded inside a Node app, PowerShell on Windows).
- Never commit, amend, or push without explicit ask.

## Windows

`Windows/` is WinGet Configuration (`tasks/*.winget`, schema 0.2), run on the Windows
machine itself by `Windows/index.ps1`.

- Iterate the same way: apply manually, port into the task file, then run only that task
  with `powershell -ExecutionPolicy Bypass -File Windows\index.ps1 <task>`.
- Confirm with `winget configure test -f Windows\tasks\<task>.winget`: every unit must
  report it is in the desired state.
- Same additive-only rule: units describe the end state, never cleanup.
- `PSDscResources/Script` blocks run under strict mode in winget's own PowerShell: reload
  PATH first, keep TestScript output to a single boolean, and pipe SetScript output to
  `Out-Null`.

## Mac

`Mac/` holds standalone scripts run on the Mac itself. Keep them out of the Proxmox and
CodingServer Ansible: they set up this client, not a server.

- `bash Mac/smb.sh` mounts the storage LXC's `ssd` and `media` SMB shares in Finder,
  reading the password from jarvis Doppler. Safe to re-run; mounted shares are skipped.
- Drive mounts drop on reboot, sleep or a network change, so they don't fit an Ansible
  steady state. Re-run the script instead of adding a playbook task.

## MCP gateway

`https://mcp.myjarvis.in/mcp` (MCPHub, container `mcp` in the Proxmox media stack) is the one
MCP server for every home service: Seerr, Jellyfin, qBittorrent and Home Assistant. Tool names
are prefixed by service (`seerr-`, `jellyfin-`, `qbittorrent-`, `homeassistant-`).

- Auth: `Authorization: Bearer <JARVIS_MCP_API_KEY>` (jarvis Doppler; Mac Keychain
  `jarvis-mcp-api-key`). Claude and ChatGPT apps use OAuth instead: sign in as `admin` with
  the same key.
- Add a service to `mcp_settings.mcpServers` in `Proxmox/tasks/instances/docker_lxc/media.yml`
  and deploy the media stack. Never add a per-service MCP to the agents.
- An upstream on a LAN IP needs `owner: admin`, or MCPHub blocks it as a private address.
- Agents carry one `jarvis` entry: Oracle via `CodingServer/templates/agents/mcp/jarvis.json.j2`.
  On the Mac, Claude uses an HTTP entry with a Keychain `headersHelper`; Codex and agy run
  `~/.mcp/jarvis-mcp.py`, a stdio bridge that re-handshakes after a gateway restart.
