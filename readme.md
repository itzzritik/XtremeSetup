# XtremeSetup

**XtremeSetup** is a collection of automation scripts designed to streamline the setup and management of distinct computing environments: **Proxmox Home Lab**, **Raspberry Pi (Jarvis)**, and **Windows Development Machine**.

---

## 🚀 Environments

### 1. Proxmox Home Lab

A complete Ansible-based automation suite for managing a Proxmox VE server. It handles the provisioning of LXC containers, Docker services, and system configurations.

**Key Features:**

-   **Infrastructure as Code:** Automated creation and management of LXC containers.
-   **Docker Integration:** Deploys complex Docker stacks (Media Server, Arr-stack, tools).
-   **Service Management:** Configures networking, storage (NFS/SMB), and application services.

**How to Run:**
From your control node (e.g., your Mac or Laptop):

```bash
./Proxmox/jarvis.sh
```

_This script will install Ansible (if missing) and execute the main playbook._

### 2. Jarvis (Raspberry Pi / Ubuntu)

A setup script for a Raspberry Pi running Ubuntu Server, transforming it into a versatile local server, AI assistant, and NAS.

**Key Features:**

-   **System Hardening:** Updates system security and configures SSH keys.
-   **Network & Storage:** Sets static IPs and automounts external drives.
-   **Services:** Installs media servers, torrent clients, and FTP services.

**Installation:**
Run the following command on your Raspberry Pi:

```bash
bash -c "$(curl -fsSL setup.myjarvis.in)"
```

### 3. Windows Development Machine

WinGet Configuration files that restore the Windows dev setup after a fresh install: VS Code, PowerShell 7, Windows Terminal, Oh My Posh, Git, fnm + Node LTS, bun, Go, just, Python, Doppler, Claude Code, and Windows dev settings.

**How to Run:**
From a normal (non-admin) PowerShell:

```powershell
irm setup-windows.ritik.me | iex
```

_It asks for one UAC approval, then runs unattended in an admin window and writes a log to `%TEMP%\jarvis-setup.log`. Re-running is safe; anything already in place is skipped._

To run only some tasks (`system`, `apps`, `toolchain`, `shell`, `git`) from a local clone:

```powershell
powershell -ExecutionPolicy Bypass -File .\Windows\index.ps1 shell git
```

**After the first run:**

1. 1Password: sign in, turn on Settings > Developer > **Use the SSH Agent**, then use **Configure Commit Signing** on your key.
2. VS Code: sign in to Settings Sync.
3. Doppler: `doppler login`.
4. Reboot once.

---

## 📂 Repository Structure

-   **`Proxmox/`**: Ansible playbooks (`*.yml`), inventory, and roles for Home Lab automation.
-   **`Jarvis/`**: Shell scripts for the Raspberry Pi/Ubuntu setup.
-   **`Windows/`**: WinGet Configuration tasks (`tasks/*.winget`), the `index.ps1` bootstrap, and the PowerShell profile and Terminal settings they deploy (`files/`).

---
