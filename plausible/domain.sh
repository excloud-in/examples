#!/bin/bash

APP_NAME="plausible"
APP_DIR="/var/excloud/apps"
APP_UPSTREAM_PORT="${EXC_APP_UPSTREAM_PORT:-8000}"

DOMAIN="${1}"

if [ -z "${DOMAIN}" ]; then
  echo "Error: URL argument is required. Example:" >&2
  echo "domain.sh sub.example.com" >&2
  exit 1
fi

PLAUSIBLE_DIR="${APP_DIR}/${APP_NAME}"
ENV_FILE="${PLAUSIBLE_DIR}/.env"
OVERRIDE_FILE="${PLAUSIBLE_DIR}/compose.override.yml"
SECRET_KEY_FILE="${PLAUSIBLE_DIR}/.secret_key_base"

if [ ! -f "${SECRET_KEY_FILE}" ]; then
  openssl rand -base64 48 > "${SECRET_KEY_FILE}"
fi

SECRET_KEY_BASE="$(tr -d '\n' < "${SECRET_KEY_FILE}")"

cat > "${ENV_FILE}" <<EOF
BASE_URL=https://${DOMAIN}
SECRET_KEY_BASE=${SECRET_KEY_BASE}
HTTP_PORT=80
EOF

cat > "${OVERRIDE_FILE}" <<EOF
services:
  plausible:
    ports:
      - "127.0.0.1:${APP_UPSTREAM_PORT}:80"
EOF

cat > /etc/caddy/Caddyfile <<EOF
https://${DOMAIN} {
        reverse_proxy 127.0.0.1:${APP_UPSTREAM_PORT}
}
EOF

echo "Caddyfile updated"

systemctl enable caddy
docker compose -f "${PLAUSIBLE_DIR}/compose.yml" -f "${OVERRIDE_FILE}" up -d
systemctl reload caddy
