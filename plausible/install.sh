#!/bin/bash

APP_NAME="plausible"
APP_DIR="/var/excloud/apps"
SCRIPT_DIR="/var/excloud/scripts"
APP_UPSTREAM_PORT="${EXC_APP_UPSTREAM_PORT:-8000}"
REPO_URL="https://github.com/plausible/community-edition.git"
REPO_REF="v3.2.0"

mkdir -p "${APP_DIR}"
mkdir -p "${SCRIPT_DIR}"

DOMAIN="${1}"

if [ -z "${DOMAIN}" ]; then
  echo "Error: URL argument is required. Example:" >&2
  echo "install.sh sub.example.com" >&2
  exit 1
fi

PLAUSIBLE_DIR="${APP_DIR}/${APP_NAME}"



if [ ! -d "${PLAUSIBLE_DIR}/.git" ]; then
  git clone -b "${REPO_REF}" --single-branch "${REPO_URL}" "${PLAUSIBLE_DIR}"
fi

bash "${SCRIPT_DIR}/domain.sh" "${DOMAIN}"
