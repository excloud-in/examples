#!/bin/bash

APP_NAME="vaultwarden"
APP_DIR="/var/excloud/apps"
APP_UPSTREAM_PORT="${EXC_APP_UPSTREAM_PORT:-8080}"

DOMAIN="${1}"

if [ -z "${DOMAIN}" ]; then
  echo "Error: URL argument is required. Example:" >&2
  echo "domain.sh sub.example.com" >&2
  exit 1
fi

VAULTWARDEN_DIR="${APP_DIR}/${APP_NAME}"
COMPOSE_FILE="${VAULTWARDEN_DIR}/docker-compose.yml"

source /var/excloud/scripts/caddy-setup.sh

if is_app_ready "$VAULTWARDEN_DIR"; then
    # Update domain in docker-compose env vars
    sed -i "s|DOMAIN: .*|DOMAIN: https://${DOMAIN}|" "${COMPOSE_FILE}"
    docker compose -f "${COMPOSE_FILE}" up -d --remove-orphans
    switch_domain "$DOMAIN" "$APP_UPSTREAM_PORT" "$VAULTWARDEN_DIR"
else
    setup_initializing_page "$DOMAIN" "$APP_NAME" "$VAULTWARDEN_DIR"
    docker compose -f "${COMPOSE_FILE}" up -d --remove-orphans
    wait_and_switch_to_proxy "$DOMAIN" "$APP_UPSTREAM_PORT" "$VAULTWARDEN_DIR" &
fi
