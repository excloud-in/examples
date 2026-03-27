#!/bin/bash

APP_NAME="nocodb"
APP_DIR="/var/excloud/apps"
SCRIPT_DIR="/var/excloud/scripts"
APP_UPSTREAM_PORT="${EXC_APP_UPSTREAM_PORT:-8080}"

mkdir -p "${APP_DIR}"
mkdir -p "${SCRIPT_DIR}"

DOMAIN="${1}"

if [ -z "${DOMAIN}" ]; then
  echo "Error: URL argument is required. Example:" >&2
  echo "install.sh sub.example.com" >&2
  exit 1
fi

NOCODB_DIR="${APP_DIR}/${APP_NAME}"
COMPOSE_FILE="${NOCODB_DIR}/docker-compose.yml"

apt-get install -y caddy
mkdir -p "${NOCODB_DIR}"

cat > "${COMPOSE_FILE}" <<EOF
services:
  nocodb:
    image: nocodb/nocodb:0.301.5
    restart: always
    ports:
      - "127.0.0.1:${APP_UPSTREAM_PORT}:8080"
    volumes:
      - nocodb-data:/usr/app/data
volumes:
  nocodb-data:
EOF

bash "${SCRIPT_DIR}/domain.sh" "${DOMAIN}"
