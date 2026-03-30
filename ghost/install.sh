#!/bin/bash

APP_NAME="ghost"
APP_DIR="/var/excloud/apps"
SCRIPT_DIR="/var/excloud/scripts"
APP_UPSTREAM_PORT="${EXC_APP_UPSTREAM_PORT:-2368}"
REPO_URL="https://github.com/TryGhost/ghost-docker.git"

mkdir -p "${APP_DIR}"
mkdir -p "${SCRIPT_DIR}"

DOMAIN="${1}"

if [ -z "${DOMAIN}" ]; then
  echo "Error: URL argument is required. Example:" >&2
  echo "install.sh sub.example.com" >&2
  exit 1
fi

GHOST_DIR="${APP_DIR}/${APP_NAME}"
BOOTSTRAP_DIR="${APP_DIR}/.${APP_NAME}-bootstrap"

mkdir -p "${BOOTSTRAP_DIR}"
source /var/excloud/scripts/caddy-setup.sh
setup_initializing_page "$DOMAIN" "$APP_NAME" "$BOOTSTRAP_DIR"

apt-get install -y git openssl

if [ ! -d "${GHOST_DIR}/.git" ]; then
  git clone "${REPO_URL}" "${GHOST_DIR}"
fi

bash "${SCRIPT_DIR}/domain.sh" "${DOMAIN}"
