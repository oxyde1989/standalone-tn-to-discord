# 📬 Stand-alone TrueNAS --> Discord Send message Script  
---

## 📌 What this script do

This script is a simple wrapper to send messages from Truenas to a Discord chat using webhooks.
There are 3 args to fill in:
- `-w` the webhook endpoint (required)
- `-m` the message you want to send (markdown also is supported, but pay attention to the correct format)
- `-s` optionally, the sender name (if not provided, the hostname/`Truenas BOT` will be automatically used)

---

## 🐞 Debugging

In case of need, passing `--debug_enabled` as arg to the script will activate the debug mode: every step will be printed to help troubleshooting.

---

## 🔐 Security Concern

The script shouldn't require particular privilegies, but ensure to only run it in a secured folder, not accessible to un-priviliged users, to avoid unexpected behaviour.

---

## 🙋‍♂️ For any problem or improvements let me know!

---

## 📘 Basic Example

### ✅ Method 1

```bash
#!/bin/bash
export DISCORD_WEBHOOK_URL=https://discord.com/api/webhooks/***
python3 tn-to-discord.py \
    -w "$DISCORD_WEBHOOK_URL" \
    -m $'**[System Report](https://example.com)**\n\n> **Task completed** successfully on _pool_ `MyDataPool`\n> Total time: `12m 33s`\n> Status: ✅\n\n__Details:__\n• Dataset: `pool/data`\n• Size: 123 GB\n• Snapshot: `snap_2025-08-11`\n\n```bash\nzfs list -o name,used,avail\n```\n\n~~No errors detected~~' \
    -s "TnToDiscord"
```
### ✅ Method 2 (Cron Jobs)

> When running from the Cron Job scheduler, use `printf '%b'` instead of `ANSI-C quoting` to interpret `\n` as real newlines:

```bash
#!/bin/sh
cd /mnt/mypool/mysecurefolder &&
export DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/***" &&
python3 /mnt/pool/scripts/tn-to-discord.py \
    -w "$DISCORD_WEBHOOK_URL" \
    -m "$(printf '%b' '**[System Report](https://example.com)**\n\n> **Task completed** successfully on _pool_ `MyDataPool`\n> Total time: `12m 33s`\n> Status: ✅\n\n__Details:__\n• Dataset: `pool/data`\n• Size: 123 GB\n• Snapshot: `snap_2025-08-11`\n\n```bash\nzfs list -o name,used,avail\n```\n\n~~No errors detected~~')" \
    -s "TnToDiscord"
```
