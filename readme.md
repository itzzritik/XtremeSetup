# XtremeSetup

This repository contains scripts for the initial setup of two different environments:

1. **Jarvis** - A local server, AI assistant, and Network Attached Storage (NAS) running on a Raspberry Pi with Ubuntu Server.
2. **Windows Machine** - A setup for a development environment.

## Jarvis Setup

Running on a Raspberry Pi with Ubuntu 23, Jarvis acts as a local server, AI assistant, and NAS, providing a personalized and efficient environment. 

This script ensures up-to-date system security, facilitates secure communication via SSH keys, and maintains consistent network access through a static IP. Automating drive mounting for easy data access, managing media servers and torrents for entertainment, and enabling quick file transfers with FTP servers are among its many capabilities. 


### How to Run Jarvis Setup

To run the Jarvis setup, use the following command:

```
bash -c "$(curl -fsSL ritik.me/jarvis-setup)"
```

This command downloads the setup script and executes it.

## Windows Machine Setup

The Windows machine setup is intended for setting up a development environment.