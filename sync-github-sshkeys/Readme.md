# Sync GitHub Team SSH Keys to Root

This tool automatically syncs the SSH public keys of all members of a GitHub team into the `root` user’s `~/.ssh/authorized_keys`.  
It is useful for managing server access in organizations where team membership on GitHub defines who should have SSH access.  

---

## Features
- Syncs SSH keys from a GitHub team into `root`’s authorized keys  
- Backs up old keys automatically  
- Installs as a cronjob (runs hourly by default)  
- Interactive setup: select your organization and team from GitHub  
- Stores your GitHub token securely in `/root/.github-token`  

---

## Requirements
- Linux server with root access  
- `curl` and `jq` installed  
- GitHub [Personal Access Token (PAT)](https://github.com/settings/tokens) with **`read:org`** scope  

---

## Quick Install

Run this as root:

```bash
curl -s https://raw.githubusercontent.com/excloud-in/examples/main/sync-github-sshkeys/install.sh | bash
