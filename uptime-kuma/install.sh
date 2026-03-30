#!/bin/bash

APP_NAME="uptime-kuma"
APP_DIR="/var/excloud/apps"
SCRIPT_DIR="/var/excloud/scripts"
APP_UPSTREAM_PORT="${EXC_APP_UPSTREAM_PORT:-3001}"

mkdir -p "${APP_DIR}"
mkdir -p "${SCRIPT_DIR}"

DOMAIN="${1}"

if [ -z "${DOMAIN}" ]; then
  echo "Error: URL argument is required. Example:" >&2
  echo "install.sh sub.example.com" >&2
  exit 1
fi

UPTIME_KUMA_DIR="${APP_DIR}/${APP_NAME}"
COMPOSE_FILE="${UPTIME_KUMA_DIR}/docker-compose.yml"

apt-get install -y caddy
mkdir -p "${UPTIME_KUMA_DIR}"

cat > "${COMPOSE_FILE}" <<EOF
services:
  uptime-kuma:
    image: louislam/uptime-kuma:2
    restart: always
    ports:
      - "127.0.0.1:${APP_UPSTREAM_PORT}:3001"
    volumes:
      - uptime-kuma:/app/data
volumes:
  uptime-kuma:
EOF

bash "${SCRIPT_DIR}/domain.sh" "${DOMAIN}"
