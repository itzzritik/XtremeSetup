# Agent Rules

These rules apply to the **Ansible-provisioned hosts** in this repo: `Oracle/` and `Proxmox/`.
Each has its own playbook at `<host>/main.yml` (other directories like `Jarvis/` and
`Windows/` are not Ansible).

## Iterating on an Ansible change

1. Apply manually on the target host, verify it works.
2. Port the working change into that host's Ansible playbook.
3. Comment out unrelated entries in `<host>/main.yml` loops so only the task you're
   testing runs.
4. Run `ansible-playbook -i <host>/inventory.ini <host>/main.yml` — confirm the touched
   task reports `ok` (idempotent against the manual fix).
5. Revert the comments in `<host>/main.yml`.

Don't re-run the full playbook to iterate.

## Conventions

- Idempotent re-runs must report `changed=0` for touched services.
- Ansible tasks are additive only — they describe the desired steady state.
  Never add tasks that exist purely to clean up something (e.g. `state: absent`,
  `docker rm -f`, "Remove Legacy X"). Cleanup is a one-time manual step on the
  host; the playbook should reflect the world afterward, not the migration path.
- Patch source files via `blockinfile` with named markers, not `replace` regex.
- New playbooks must mirror the structure and style of existing siblings in the same
  `<host>/tasks/` directory (vars layout, task naming `'{{ app_name | upper }}: ...'`,
  ordering, indentation, etc).
- Never commit, amend, or push without explicit ask.
