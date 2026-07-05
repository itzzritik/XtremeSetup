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

### Detect the runtime host first

Before invoking any Oracle play, determine whether you're on the Oracle box or
remote. Running `main.yml` on Oracle makes it SSH from Oracle to itself via the
inventory IP — wrong and forbidden.

Don't rely on `hostname -I` — it returns Oracle's private VPC IP (`10.x.x.x`),
not the public IP in `inventory.ini`.

Detection:

```bash
ORACLE_IP=$(awk '/^oracle / {for(i=1;i<=NF;i++) if($i ~ /^ansible_host=/) {split($i,a,"="); print a[2]}}' Oracle/inventory.ini)

# Fast offline check: only OCI VMs have this metadata endpoint.
if curl -fsm 1 http://169.254.169.254/opc/v1/instance/id >/dev/null 2>&1; then
    # Confirm we're THE Oracle box (vs some other OCI VM) by matching egress IP.
    [ "$(curl -fsm 3 https://ipv4.icanhazip.com 2>/dev/null)" = "$ORACLE_IP" ] \
        && echo "on-oracle" || echo "remote"
else
    echo "remote"
fi
```

- `on-oracle` → use `Oracle/oracle-local.yml`
- `remote` (Mac or elsewhere) → use `Oracle/main.yml` (the normal SSH flow)

### Running on Oracle itself (no Mac, no SSH)

`Oracle/main.yml` is built for the Mac-driven flow: the `local` play fetches Doppler
secrets via `homebrew`, then the `oracle_machines` play SSHes to `144.24.124.129`.
Neither fits when you're already on the Oracle box.

Use `Oracle/oracle-local.yml` for that case — it runs one system task on
`localhost` with no Doppler dependency, hard-coding the `local_config` values
that the main env phase would normally provide.

```bash
cd Oracle
ansible-playbook oracle-local.yml                       # default task: aiven-keepalive
ansible-playbook oracle-local.yml -e 'task=neveridle'   # any task under tasks/system/
```

The canonical task lives in `tasks/system/<task>.yml` and is still picked up by
the normal Mac-driven `main.yml` run — `oracle-local.yml` is just an alternate
entry point, not a divergent definition.

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
