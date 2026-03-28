#!/bin/bash

APP_NAME="metabase"
APP_DIR="/var/excloud/apps"
APP_UPSTREAM_PORT="${EXC_APP_UPSTREAM_PORT:-3000}"

DOMAIN="${1}"

if [ -z "${DOMAIN}" ]; then
  echo "Error: URL argument is required. Example:" >&2
  echo "domain.sh sub.example.com" >&2
  exit 1
fi

METABASE_DIR="${APP_DIR}/${APP_NAME}"
COMPOSE_FILE="${METABASE_DIR}/docker-compose.yml"

source /var/excloud/scripts/caddy-setup.sh

if is_app_ready "$METABASE_DIR"; then
    # Update domain in docker-compose env vars
    sed -i "s|MB_SITE_URL: .*|MB_SITE_URL: https://${DOMAIN}|" "${COMPOSE_FILE}"
    docker compose -f "${COMPOSE_FILE}" up -d --remove-orphans
    switch_domain "$DOMAIN" "$APP_UPSTREAM_PORT" "$METABASE_DIR"
else
    setup_initializing_page "$DOMAIN" "$APP_NAME" "$METABASE_DIR"
    docker compose -f "${COMPOSE_FILE}" up -d --remove-orphans
    wait_and_switch_to_proxy "$DOMAIN" "$APP_UPSTREAM_PORT" "$METABASE_DIR" &
fi
