Steps to install ERPNext on [Excloud](https://excloud.in)

### Minimum Requirements:
- Instance: `t1.small`
- Disk: `8GB`

### Overview

This scripts creates a secure installation for ERPNext. The secure password is stored at the path `/var/frappe/admin-password`

### Commands to Install

#### Clone Repo
```bash
git clone https://github.com/excloud-in/examples
```
#### Install ERPNext
```bash
cd examples/erpnext
bash install-erpnext.sh
```

Note: It takes 1-2 mins for ERPNext to bootstrap wait for it.
