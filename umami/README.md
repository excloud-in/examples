Steps to install [Umami](https://umami.is) (privacy-friendly web analytics) on [Excloud](https://excloud.in)

### Minimum Requirements
- Instance: `t1.small`
- Disk: `8GB`

### Overview
Self-contained deployment: the Umami app plus a PostgreSQL 16 database. A random
`APP_SECRET` and database password are generated on first install and persisted
to `.app_secret` / `.database_password` so re-runs stay stable.

The app is bound to `127.0.0.1:3000` and served publicly over HTTPS by Caddy.

### Install
```bash
bash install.sh sub.example.com
```

### First login
Umami ships with a default admin account — **change the password immediately**:
- Username: `admin`
- Password: `umami`
