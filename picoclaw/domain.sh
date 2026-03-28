#!/bin/bash

APP_NAME="picoclaw"
APP_DIR="/var/excloud/apps"
APP_UPSTREAM_PORT="${EXC_APP_UPSTREAM_PORT:-18800}"
APP_BRIDGE_PORT="${EXC_APP_BRIDGE_PORT:-18790}"

DOMAIN="${1}"

if [ -z "${DOMAIN}" ]; then
  echo "Error: URL argument is required. Example:" >&2
  echo "domain.sh sub.example.com" >&2
  exit 1
fi

PICOCLAW_DIR="${APP_DIR}/${APP_NAME}"
DATA_DIR="${PICOCLAW_DIR}/docker/data"
CONFIG_FILE="${DATA_DIR}/config.json"
OVERRIDE_FILE="${PICOCLAW_DIR}/docker/compose.override.yml"

mkdir -p "${DATA_DIR}/workspace"

if [ ! -f "${CONFIG_FILE}" ]; then
  cp "${PICOCLAW_DIR}/config/config.example.json" "${CONFIG_FILE}"
fi

cat > "${OVERRIDE_FILE}" <<EOF
services:
  picoclaw-launcher:
    ports:
      - "127.0.0.1:${APP_UPSTREAM_PORT}:18800"
      - "127.0.0.1:${APP_BRIDGE_PORT}:18790"
EOF

source /var/excloud/scripts/caddy-setup.sh

if is_app_ready "$PICOCLAW_DIR"; then
    switch_domain "$DOMAIN" "$APP_UPSTREAM_PORT" "$PICOCLAW_DIR"
else
    setup_initializing_page "$DOMAIN" "$APP_NAME" "$PICOCLAW_DIR"
    cd "${PICOCLAW_DIR}"
    docker compose -f docker/docker-compose.yml -f docker/compose.override.yml --profile launcher up -d
    wait_and_switch_to_proxy "$DOMAIN" "$APP_UPSTREAM_PORT" "$PICOCLAW_DIR" &
fi
