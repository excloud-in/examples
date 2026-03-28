#!/bin/bash

APP_NAME="open-webui"
APP_DIR="/var/excloud/apps"
APP_UPSTREAM_PORT="${EXC_APP_UPSTREAM_PORT:-3000}"

DOMAIN="${1}"

if [ -z "${DOMAIN}" ]; then
  echo "Error: URL argument is required. Example:" >&2
  echo "domain.sh sub.example.com" >&2
  exit 1
fi

COMPOSE_FILE="${APP_DIR}/${APP_NAME}/docker-compose.yml"

source /var/excloud/scripts/caddy-setup.sh

if is_app_ready "$APP_DIR/$APP_NAME"; then
    switch_domain "$DOMAIN" "$APP_UPSTREAM_PORT" "$APP_DIR/$APP_NAME"
else
    setup_initializing_page "$DOMAIN" "$APP_NAME" "$APP_DIR/$APP_NAME"
    docker compose -f "${COMPOSE_FILE}" up -d --remove-orphans
    wait_and_switch_to_proxy "$DOMAIN" "$APP_UPSTREAM_PORT" "$APP_DIR/$APP_NAME" &
fi
