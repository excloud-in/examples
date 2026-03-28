#!/bin/bash

APP_NAME="n8n"
APP_DIR="/var/excloud/apps"
APP_UPSTREAM_PORT="${EXC_APP_UPSTREAM_PORT:-5678}"

DOMAIN="${1}"

if [ -z "${DOMAIN}" ]; then
  echo "Error: URL argument is required. Example:" >&2
  echo "domain.sh sub.example.com" >&2
  exit 1
fi

N8N_DIR="${APP_DIR}/${APP_NAME}"
COMPOSE_FILE="${N8N_DIR}/docker-compose.yml"

source /var/excloud/scripts/caddy-setup.sh

if is_app_ready "$N8N_DIR"; then
    # Update domain in docker-compose env vars
    sed -i \
      -e "s|N8N_HOST: .*|N8N_HOST: ${DOMAIN}|" \
      -e "s|WEBHOOK_URL: .*|WEBHOOK_URL: https://${DOMAIN}/|" \
      "${COMPOSE_FILE}"
    docker compose -f "${COMPOSE_FILE}" up -d --remove-orphans
    switch_domain "$DOMAIN" "$APP_UPSTREAM_PORT" "$N8N_DIR"
else
    setup_initializing_page "$DOMAIN" "$APP_NAME" "$N8N_DIR"
    docker compose -f "${COMPOSE_FILE}" up -d --remove-orphans
    wait_and_switch_to_proxy "$DOMAIN" "$APP_UPSTREAM_PORT" "$N8N_DIR" &
fi
