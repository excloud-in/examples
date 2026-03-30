#!/bin/bash

APP_NAME="metabase"
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

METABASE_DIR="${APP_DIR}/${APP_NAME}"
COMPOSE_FILE="${METABASE_DIR}/docker-compose.yml"


mkdir -p "${METABASE_DIR}"

cat > "${COMPOSE_FILE}" <<EOF
services:
  metabase:
    image: metabase/metabase:v0.59.1
    restart: always
    ports:
      - "127.0.0.1:${APP_UPSTREAM_PORT}:3000"
    environment:
      MB_SITE_URL: https://${DOMAIN}
      MB_DB_FILE: /metabase-data/metabase.db
    volumes:
      - metabase-data:/metabase-data
volumes:
  metabase-data:
EOF

bash "${SCRIPT_DIR}/domain.sh" "${DOMAIN}"
