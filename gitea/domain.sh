#!/bin/bash

APP_NAME="gitea"
APP_DIR="/var/excloud/apps"
APP_UPSTREAM_PORT="${EXC_APP_UPSTREAM_PORT:-3000}"

DOMAIN="${1}"

if [ -z "${DOMAIN}" ]; then
  echo "Error: URL argument is required. Example:" >&2
  echo "domain.sh sub.example.com" >&2
  exit 1
fi

GITEA_DIR="${APP_DIR}/${APP_NAME}"
COMPOSE_FILE="${GITEA_DIR}/docker-compose.yml"

source /var/excloud/scripts/caddy-setup.sh

if is_app_ready "$GITEA_DIR"; then
    # Update domain in docker-compose env vars
    sed -i \
      -e "s|GITEA__server__ROOT_URL: .*|GITEA__server__ROOT_URL: https://${DOMAIN}/|" \
      -e "s|GITEA__server__DOMAIN: .*|GITEA__server__DOMAIN: ${DOMAIN}|" \
      -e "s|GITEA__server__SSH_DOMAIN: .*|GITEA__server__SSH_DOMAIN: ${DOMAIN}|" \
      "${COMPOSE_FILE}"
    docker compose -f "${COMPOSE_FILE}" up -d --remove-orphans
    switch_domain "$DOMAIN" "$APP_UPSTREAM_PORT" "$GITEA_DIR"
else
    setup_initializing_page "$DOMAIN" "$APP_NAME" "$GITEA_DIR"
    docker compose -f "${COMPOSE_FILE}" up -d --remove-orphans
    wait_and_switch_to_proxy "$DOMAIN" "$APP_UPSTREAM_PORT" "$GITEA_DIR" &
fi
