#!/bin/bash

APP_NAME="erpnext"
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

ERPNEXT_DIR="${APP_DIR}/${APP_NAME}"
STATE_DIR="${ERPNEXT_DIR}/.excloud"
COMPOSE_FILE="${ERPNEXT_DIR}/pwd.yml"
ADMIN_PASSWORD_FILE="${STATE_DIR}/admin-password"

apt-get install -y caddy git openssl

if git -C "${ERPNEXT_DIR}" rev-parse 2>/dev/null; then
  echo "Git repo exists"
else
  rm -rf "${ERPNEXT_DIR}"
  git clone --depth 1 https://github.com/frappe/frappe_docker.git "${ERPNEXT_DIR}"
fi

mkdir -p "${STATE_DIR}"

if [ -f "${ADMIN_PASSWORD_FILE}" ]; then
  ADMIN_PASSWORD="$(cat "${ADMIN_PASSWORD_FILE}")"
elif [ -n "${EXC_APP_BOOTSTRAP_ADMIN_PASSWORD:-}" ]; then
  ADMIN_PASSWORD="${EXC_APP_BOOTSTRAP_ADMIN_PASSWORD}"
  echo "${ADMIN_PASSWORD}" > "${ADMIN_PASSWORD_FILE}"
else
  ADMIN_PASSWORD="$(openssl rand -hex 18)"
  echo "${ADMIN_PASSWORD}" > "${ADMIN_PASSWORD_FILE}"
fi

git -C "${ERPNEXT_DIR}" show HEAD:pwd.yml > "${STATE_DIR}/pwd.yml.orig"
cp "${STATE_DIR}/pwd.yml.orig" "${COMPOSE_FILE}"

sed -i \
  -e "s/MYSQL_ROOT_PASSWORD: admin/MYSQL_ROOT_PASSWORD: ${ADMIN_PASSWORD}/g" \
  -e "s/MARIADB_ROOT_PASSWORD: admin/MARIADB_ROOT_PASSWORD: ${ADMIN_PASSWORD}/g" \
  -e "s/--admin-password=admin/--admin-password=${ADMIN_PASSWORD}/" \
  -e "s/--db-root-password=admin/--db-root-password=${ADMIN_PASSWORD}/" \
  -e "s/--password=admin/--password=${ADMIN_PASSWORD}/" \
  "${COMPOSE_FILE}"
sed -i "s/\"8080:8080\"/\"127.0.0.1:${APP_UPSTREAM_PORT}:8080\"/" "${COMPOSE_FILE}"

docker compose -f "${COMPOSE_FILE}" up -d

start_time="$(date +%s)"
while true; do
  if curl -fsS "http://127.0.0.1:${APP_UPSTREAM_PORT}" >/dev/null 2>&1; then
    break
  fi

  if [ $(( $(date +%s) - start_time )) -ge 900 ]; then
    echo "ERPNext did not become ready in time" >&2
    exit 1
  fi

  sleep 5
done

bash "${SCRIPT_DIR}/domain.sh" "${DOMAIN}"
