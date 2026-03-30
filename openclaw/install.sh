#!/bin/bash

APP_NAME="openclaw"
APP_DIR="/var/excloud/apps"
SCRIPT_DIR="/var/excloud/scripts"
REPO_URL="https://github.com/openclaw/openclaw.git"

mkdir -p "${APP_DIR}"
mkdir -p "${SCRIPT_DIR}"

DOMAIN="${1}"

if [ -z "${DOMAIN}" ]; then
  echo "Error: URL argument is required. Example:" >&2
  echo "install.sh sub.example.com" >&2
  exit 1
fi

OPENCLAW_DIR="${APP_DIR}/${APP_NAME}"

apt-get install -y caddy git openssl

if [ ! -d "${OPENCLAW_DIR}/.git" ]; then
  git clone "${REPO_URL}" "${OPENCLAW_DIR}"
fi

bash "${SCRIPT_DIR}/domain.sh" "${DOMAIN}"
