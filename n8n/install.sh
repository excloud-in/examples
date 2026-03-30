#!/bin/bash

APP_NAME="n8n"
APP_DIR="/var/excloud/apps"
SCRIPT_DIR="/var/excloud/scripts"
APP_UPSTREAM_PORT="${EXC_APP_UPSTREAM_PORT:-5678}"

mkdir -p "${APP_DIR}"
mkdir -p "${SCRIPT_DIR}"

DOMAIN="${1}"

if [ -z "${DOMAIN}" ]; then
  echo "Error: URL argument is required. Example:" >&2
  echo "install.sh sub.example.com" >&2
  exit 1
fi

N8N_DIR="${APP_DIR}/${APP_NAME}"
COMPOSE_FILE="${N8N_DIR}/docker-compose.yml"

apt-get install -y caddy
mkdir -p "${N8N_DIR}"

cat > "${COMPOSE_FILE}" <<EOF
services:
  n8n:
    image: docker.n8n.io/n8nio/n8n:2.12.3
    restart: always
    ports:
      - "127.0.0.1:${APP_UPSTREAM_PORT}:5678"
    environment:
      GENERIC_TIMEZONE: UTC
      TZ: UTC
      N8N_SECURE_COOKIE: "true"
      N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS: "true"
      N8N_RUNNERS_ENABLED: "true"
      N8N_HOST: ${DOMAIN}
      N8N_PROTOCOL: https
      WEBHOOK_URL: https://${DOMAIN}/
    volumes:
      - n8n_data:/home/node/.n8n
volumes:
  n8n_data:
EOF

bash "${SCRIPT_DIR}/domain.sh" "${DOMAIN}"
