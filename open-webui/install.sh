#!/bin/bash

APP_NAME="open-webui"
APP_DIR="/var/excloud/apps"
SCRIPT_DIR="/var/excloud/scripts"
APP_UPSTREAM_PORT="${EXC_APP_UPSTREAM_PORT:-3000}"

mkdir -p "${APP_DIR}"
mkdir -p "${SCRIPT_DIR}"

DOMAIN="${1}"

if [ -z "${DOMAIN}" ]; then
  echo "Error: URL argument is required. Example:" >&2
  echo "install.sh sub.example.com" >&2
  exit 1
fi

OPEN_WEBUI_DIR="${APP_DIR}/${APP_NAME}"
COMPOSE_FILE="${OPEN_WEBUI_DIR}/docker-compose.yml"

mkdir -p "${OPEN_WEBUI_DIR}"
source /var/excloud/scripts/caddy-setup.sh
setup_initializing_page "$DOMAIN" "$APP_NAME" "$OPEN_WEBUI_DIR"

apt-get install -y openssl

WEBUI_SECRET_KEY="$(openssl rand -hex 32)"

cat > "${COMPOSE_FILE}" <<EOF
services:
  open-webui:
    image: ghcr.io/open-webui/open-webui:v0.8.6
    restart: always
    ports:
      - "127.0.0.1:${APP_UPSTREAM_PORT}:8080"
    environment:
      WEBUI_SECRET_KEY: "${WEBUI_SECRET_KEY}"
    volumes:
      - open-webui:/app/backend/data
volumes:
  open-webui:
EOF

bash "${SCRIPT_DIR}/domain.sh" "${DOMAIN}"
