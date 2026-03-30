#!/bin/bash

APP_NAME="vaultwarden"
APP_DIR="/var/excloud/apps"
SCRIPT_DIR="/var/excloud/scripts"
APP_UPSTREAM_PORT="${EXC_APP_UPSTREAM_PORT:-8080}"

mkdir -p "${APP_DIR}"
mkdir -p "${SCRIPT_DIR}"

DOMAIN="${1}"

if [ -z "${DOMAIN}" ]; then
  echo "Error: URL argument is required. Example:" >&2
  echo "install.sh sub.example.com" >&2
  exit 1
fi

VAULTWARDEN_DIR="${APP_DIR}/${APP_NAME}"
COMPOSE_FILE="${VAULTWARDEN_DIR}/docker-compose.yml"

mkdir -p "${VAULTWARDEN_DIR}"
source /var/excloud/scripts/caddy-setup.sh
setup_initializing_page "$DOMAIN" "$APP_NAME" "$VAULTWARDEN_DIR"

cat > "${COMPOSE_FILE}" <<EOF
services:
  vaultwarden:
    image: vaultwarden/server:1.26.0
    restart: always
    ports:
      - "127.0.0.1:${APP_UPSTREAM_PORT}:80"
    environment:
      DOMAIN: https://${DOMAIN}
      SIGNUPS_ALLOWED: "true"
    volumes:
      - vaultwarden-data:/data
volumes:
  vaultwarden-data:
EOF

bash "${SCRIPT_DIR}/domain.sh" "${DOMAIN}"
