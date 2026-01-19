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

A PowerShell-based toolkit for setting up a fresh Windows environment for development work.

**How to Run:**

1. Open PowerShell as **Administrator**.
2. Navigate to the `Windows` directory in this repository.
3. Execute the setup script:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; .\Windows\setup.ps1
```

---

## 📂 Repository Structure

-   **`Proxmox/`**: Ansible playbooks (`*.yml`), inventory, and roles for Home Lab automation.
-   **`Jarvis/`**: Shell scripts for the Raspberry Pi/Ubuntu setup.
-   **`Windows/`**: PowerShell scripts and configuration files for Windows.

---
