#!/bin/bash

APP_NAME="signoz"
APP_DIR="/var/excloud/apps"
SCRIPT_DIR="/var/excloud/scripts"
APP_UPSTREAM_PORT="${EXC_APP_UPSTREAM_PORT:-8080}"
mkdir -p "${APP_DIR}"
mkdir -p "${SCRIPT_DIR}"

DOMAIN="${1}"

if [ -z "$DOMAIN" ]; then
  echo "Error: URL argument is required. Example:" >&2
  echo "install.sh sub.example.com" >&2
  exit 1
fi

JWT_SECRET=$(openssl rand -hex 16 | cut -c-32)
SIGNOZ_DIR="${APP_DIR}/signoz"
BOOTSTRAP_DIR="${APP_DIR}/.${APP_NAME}-bootstrap"
STATE_DIR="${SIGNOZ_DIR}/.excloud"

mkdir -p "${BOOTSTRAP_DIR}"
source /var/excloud/scripts/caddy-setup.sh
setup_initializing_page "$DOMAIN" "$APP_NAME" "$BOOTSTRAP_DIR"

# SigNoz deprecated deploy/docker and install.sh in v0.130.0.
# Foundry (foundryctl) is now the official install method.
if command -v foundryctl >/dev/null 2>&1; then
    echo "foundryctl already installed"
else
    curl -fsSL https://signoz.io/foundry.sh | FOUNDRY_INSTALL_DIR=/usr/local/bin bash
fi

mkdir -p "${STATE_DIR}" "${SIGNOZ_DIR}"
JWT_SECRET_FILE="${STATE_DIR}/jwt-secret"

if [ -f "${JWT_SECRET_FILE}" ]; then
    JWT_SECRET=$(cat "${JWT_SECRET_FILE}")
else
    echo "${JWT_SECRET}" > "${JWT_SECRET_FILE}"
fi

bash "${SCRIPT_DIR}/domain.sh" "${DOMAIN}"
