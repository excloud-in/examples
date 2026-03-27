#!/bin/bash

APP_NAME="ghost"
APP_DIR="/var/excloud/apps"
APP_UPSTREAM_PORT="${EXC_APP_UPSTREAM_PORT:-2368}"

DOMAIN="${1}"

if [ -z "${DOMAIN}" ]; then
  echo "Error: URL argument is required. Example:" >&2
  echo "domain.sh sub.example.com" >&2
  exit 1
fi

GHOST_DIR="${APP_DIR}/${APP_NAME}"
ENV_FILE="${GHOST_DIR}/.env"
OVERRIDE_FILE="${GHOST_DIR}/compose.override.yml"
ROOT_PASSWORD_FILE="${GHOST_DIR}/.database_root_password"
DATABASE_PASSWORD_FILE="${GHOST_DIR}/.database_password"

if [ ! -f "${ROOT_PASSWORD_FILE}" ]; then
  openssl rand -hex 32 > "${ROOT_PASSWORD_FILE}"
fi

if [ ! -f "${DATABASE_PASSWORD_FILE}" ]; then
  openssl rand -hex 32 > "${DATABASE_PASSWORD_FILE}"
fi

DATABASE_ROOT_PASSWORD="$(cat "${ROOT_PASSWORD_FILE}")"
DATABASE_PASSWORD="$(cat "${DATABASE_PASSWORD_FILE}")"

cat > "${ENV_FILE}" <<EOF
DOMAIN=${DOMAIN}
DATABASE_ROOT_PASSWORD=${DATABASE_ROOT_PASSWORD}
DATABASE_PASSWORD=${DATABASE_PASSWORD}
UPLOAD_LOCATION=./data/ghost
MYSQL_DATA_LOCATION=./data/mysql
EOF

cat > "${OVERRIDE_FILE}" <<EOF
services:
  ghost:
    ports:
      - "127.0.0.1:${APP_UPSTREAM_PORT}:2368"
EOF

cat > /etc/caddy/Caddyfile <<EOF
https://${DOMAIN} {
        reverse_proxy 127.0.0.1:${APP_UPSTREAM_PORT}
}
EOF

echo "Caddyfile updated"

systemctl enable caddy
docker compose -f "${GHOST_DIR}/compose.yml" -f "${OVERRIDE_FILE}" up -d db ghost
systemctl reload caddy
