#!/bin/bash

APP_NAME="erpnext"
APP_DIR="/var/excloud/apps"
APP_UPSTREAM_PORT="${EXC_APP_UPSTREAM_PORT:-8080}"

DOMAIN="${1}"

if [ -z "${DOMAIN}" ]; then
  echo "Error: URL argument is required. Example:" >&2
  echo "domain.sh sub.example.com" >&2
  exit 1
fi

ERPNEXT_DIR="${APP_DIR}/${APP_NAME}"
COMPOSE_FILE="${ERPNEXT_DIR}/pwd.yml"

source /var/excloud/scripts/caddy-setup.sh

if is_app_ready "$ERPNEXT_DIR"; then
    # Update ERPNext site host_name for correct URLs in emails/redirects
    docker compose -f "${COMPOSE_FILE}" exec -T backend bench --site frontend set-config host_name "https://${DOMAIN}"
    docker compose -f "${COMPOSE_FILE}" restart backend frontend websocket
    switch_domain "$DOMAIN" "$APP_UPSTREAM_PORT" "$ERPNEXT_DIR"
else
    setup_initializing_page "$DOMAIN" "$APP_NAME" "$ERPNEXT_DIR"
    wait_and_switch_to_proxy "$DOMAIN" "$APP_UPSTREAM_PORT" "$ERPNEXT_DIR" &
fi
