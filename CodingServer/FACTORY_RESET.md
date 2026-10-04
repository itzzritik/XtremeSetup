# Factory Reset (Oracle)

> **Never terminate the instance.** ARM64 free tier capacity is limited, you may not get it back.
> **Never go above 200 GB of storage, not even for a second.** Boot volumes, block volumes and backups all count. Never use Replace Boot Volume: it creates the new volume before deleting the old one.

1. Log in to the OCI CLI on the Mac, if not already
2. Reinstall the latest Ubuntu LTS (aarch64) in place on the existing 200 GB boot volume, with user `ubuntu`, passwordless sudo and the Mac's SSH key. If it fails, recover through the serial console, never by replacing or attaching another volume
3. Confirm Block Storage shows exactly one 200 GB boot volume, and no block volumes or backups, and that `/` fills the disk
4. On the Mac: `ssh-keygen -R <oracle ip>`, then run `bash CodingServer/index.sh oracle`
