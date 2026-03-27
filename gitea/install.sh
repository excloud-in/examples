#!/bin/bash

APP_NAME="gitea"
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

GITEA_DIR="${APP_DIR}/${APP_NAME}"
COMPOSE_FILE="${GITEA_DIR}/docker-compose.yml"

apt-get install -y caddy
mkdir -p "${GITEA_DIR}"

cat > "${COMPOSE_FILE}" <<EOF
services:
  gitea:
    image: gitea/gitea:1.25.5
    restart: always
    ports:
      - "127.0.0.1:${APP_UPSTREAM_PORT}:3000"
      - "2222:2222"
    environment:
      GITEA__server__ROOT_URL: https://${DOMAIN}/
      GITEA__server__DOMAIN: ${DOMAIN}
      GITEA__server__SSH_DOMAIN: ${DOMAIN}
      GITEA__server__SSH_PORT: "2222"
      GITEA__server__SSH_LISTEN_PORT: "2222"
    volumes:
      - gitea-data:/data
volumes:
  gitea-data:
EOF

bash "${SCRIPT_DIR}/domain.sh" "${DOMAIN}"
