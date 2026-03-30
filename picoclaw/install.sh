#!/bin/bash

APP_NAME="picoclaw"
APP_DIR="/var/excloud/apps"
SCRIPT_DIR="/var/excloud/scripts"
REPO_URL="https://github.com/sipeed/picoclaw.git"

mkdir -p "${APP_DIR}"
mkdir -p "${SCRIPT_DIR}"

DOMAIN="${1}"

if [ -z "${DOMAIN}" ]; then
  echo "Error: URL argument is required. Example:" >&2
  echo "install.sh sub.example.com" >&2
  exit 1
fi

PICOCLAW_DIR="${APP_DIR}/${APP_NAME}"



if [ ! -d "${PICOCLAW_DIR}/.git" ]; then
  git clone "${REPO_URL}" "${PICOCLAW_DIR}"
fi

bash "${SCRIPT_DIR}/domain.sh" "${DOMAIN}"
