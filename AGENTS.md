# Agent Rules

These rules apply to the Ansible projects in this repo: `CodingServer/` (both coding
servers: the Oracle VM and the Proxmox code LXC) and `Proxmox/` (the Proxmox host and
its other LXCs). Other directories like `Jarvis/` and `Windows/` are not Ansible.

Every run starts from the Mac.

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
- `CodingServer/`: full module names (`ansible.builtin.copy`, not `copy`), facts only via
  `ansible_facts.*`, and `ansible-lint` (run inside `CodingServer/`) must pass.
- Never commit, amend, or push without explicit ask.
