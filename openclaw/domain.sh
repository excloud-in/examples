#!/bin/bash

APP_NAME="openclaw"
APP_DIR="/var/excloud/apps"
APP_UPSTREAM_PORT="${EXC_APP_UPSTREAM_PORT:-18789}"
APP_BRIDGE_PORT="${EXC_APP_BRIDGE_PORT:-18790}"
OPENCLAW_IMAGE="${OPENCLAW_IMAGE:-ghcr.io/openclaw/openclaw:latest}"

DOMAIN="${1}"

if [ -z "${DOMAIN}" ]; then
  echo "Error: URL argument is required. Example:" >&2
  echo "domain.sh sub.example.com" >&2
  exit 1
fi

OPENCLAW_DIR="${APP_DIR}/${APP_NAME}"
DATA_DIR="${OPENCLAW_DIR}/data"
CONFIG_DIR="${DATA_DIR}/config"
WORKSPACE_DIR="${DATA_DIR}/workspace"
TOKEN_FILE="${OPENCLAW_DIR}/.gateway_token"
ENV_FILE="${OPENCLAW_DIR}/.env"
LEGACY_OVERRIDE_FILE="${OPENCLAW_DIR}/compose.override.yml"

mkdir -p "${CONFIG_DIR}/identity"
mkdir -p "${CONFIG_DIR}/agents/main/agent"
mkdir -p "${CONFIG_DIR}/agents/main/sessions"
mkdir -p "${WORKSPACE_DIR}"
chown -R 1000:1000 "${DATA_DIR}"

if [ ! -f "${TOKEN_FILE}" ]; then
  openssl rand -hex 32 > "${TOKEN_FILE}"
fi

OPENCLAW_GATEWAY_TOKEN="$(cat "${TOKEN_FILE}")"

cat > "${ENV_FILE}" <<EOF
OPENCLAW_IMAGE=${OPENCLAW_IMAGE}
OPENCLAW_CONFIG_DIR=${CONFIG_DIR}
OPENCLAW_WORKSPACE_DIR=${WORKSPACE_DIR}
OPENCLAW_GATEWAY_PORT=127.0.0.1:${APP_UPSTREAM_PORT}
OPENCLAW_BRIDGE_PORT=127.0.0.1:${APP_BRIDGE_PORT}
OPENCLAW_GATEWAY_BIND=lan
OPENCLAW_GATEWAY_TOKEN=${OPENCLAW_GATEWAY_TOKEN}
EOF

cd "${OPENCLAW_DIR}"
rm -f "${LEGACY_OVERRIDE_FILE}"
docker compose run --rm --no-deps --entrypoint node openclaw-gateway dist/index.js config set gateway.mode local
docker compose run --rm --no-deps --entrypoint node openclaw-gateway dist/index.js config set gateway.bind lan
docker compose run --rm --no-deps --entrypoint node openclaw-gateway dist/index.js config set gateway.controlUi.allowedOrigins "[\"https://${DOMAIN}\",\"http://localhost:${APP_UPSTREAM_PORT}\",\"http://127.0.0.1:${APP_UPSTREAM_PORT}\"]" --strict-json
docker compose -f docker-compose.yml up -d openclaw-gateway

cat > /etc/caddy/Caddyfile <<EOF
https://${DOMAIN} {
        reverse_proxy 127.0.0.1:${APP_UPSTREAM_PORT}
}
EOF

echo "Caddyfile updated"

systemctl enable caddy
systemctl reload caddy
