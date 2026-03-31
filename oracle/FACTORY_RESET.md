# Factory Reset

> **Never terminate the instance** — ARM64 free tier capacity is limited, you may not get it back.

1. Oracle Cloud Console > Compute > Instances > your instance
2. More Actions > **Replace Boot Volume**
3. Source: **Image** > Canonical Ubuntu 24.04 (aarch64)
4. Enable **Preserve Boot Volume** > Replace
5. Wait ~2 min for instance to restart
6. Run `bash oracle/index.sh`
7. Delete old boot volume from Block Storage > Boot Volumes
