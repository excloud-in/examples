#!/bin/bash

APP_NAME="jellyfin"
APP_DIR="/var/excloud/apps"
SCRIPT_DIR="/var/excloud/scripts"
APP_UPSTREAM_PORT="${EXC_APP_UPSTREAM_PORT:-8096}"

mkdir -p "${APP_DIR}"
mkdir -p "${SCRIPT_DIR}"

DOMAIN="${1}"

if [ -z "${DOMAIN}" ]; then
  echo "Error: URL argument is required. Example:" >&2
  echo "install.sh sub.example.com" >&2
  exit 1
fi

JELLYFIN_DIR="${APP_DIR}/${APP_NAME}"
COMPOSE_FILE="${JELLYFIN_DIR}/docker-compose.yml"

mkdir -p "${JELLYFIN_DIR}"
source /var/excloud/scripts/caddy-setup.sh
setup_initializing_page "$DOMAIN" "$APP_NAME" "$JELLYFIN_DIR"

mkdir -p /srv/media/movies /srv/media/shows /srv/media/music

cat > "${COMPOSE_FILE}" <<EOF
services:
  jellyfin:
    image: jellyfin/jellyfin:10.11.6
    restart: always
    ports:
      - "127.0.0.1:${APP_UPSTREAM_PORT}:8096"
    volumes:
      - jellyfin-config:/config
      - jellyfin-cache:/cache
      - /srv/media:/media
volumes:
  jellyfin-config:
  jellyfin-cache:
EOF

bash "${SCRIPT_DIR}/domain.sh" "${DOMAIN}"
