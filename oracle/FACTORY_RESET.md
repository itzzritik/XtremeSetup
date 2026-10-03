# Factory Reset

> **Never terminate the instance.** ARM64 free tier capacity is limited, you may not get it back.

1. Oracle Cloud Console > Compute > Instances > your instance
2. More Actions > **Replace Boot Volume**
3. Source: **Image** > Canonical Ubuntu 26.04 (aarch64), not Minimal
4. Boot volume size: **200 GB**
5. **Preserve Boot Volume: off**, so the old volume is deleted and storage stays within the free 200 GB
6. Click **Replace**, wait ~2 min for the instance to restart
7. On the Mac: `ssh-keygen -R <oracle ip>`, then run `bash oracle/index.sh`
