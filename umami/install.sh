#!/bin/bash

APP_NAME="umami"
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

UMAMI_DIR="${APP_DIR}/${APP_NAME}"
COMPOSE_FILE="${UMAMI_DIR}/docker-compose.yml"
APP_SECRET_FILE="${UMAMI_DIR}/.app_secret"
DB_PASSWORD_FILE="${UMAMI_DIR}/.database_password"

mkdir -p "${UMAMI_DIR}"
source /var/excloud/scripts/caddy-setup.sh
setup_initializing_page "$DOMAIN" "$APP_NAME" "$UMAMI_DIR"

# Persist generated secrets so re-runs don't invalidate sessions / break the DB.
if [ ! -f "${APP_SECRET_FILE}" ]; then
  openssl rand -hex 32 > "${APP_SECRET_FILE}"
fi
if [ ! -f "${DB_PASSWORD_FILE}" ]; then
  openssl rand -hex 32 > "${DB_PASSWORD_FILE}"
fi

APP_SECRET="$(cat "${APP_SECRET_FILE}")"
DATABASE_PASSWORD="$(cat "${DB_PASSWORD_FILE}")"

cat > "${COMPOSE_FILE}" <<EOF
services:
  umami:
    image: ghcr.io/umami-software/umami:postgresql-v2.19.0
    restart: always
    ports:
      - "127.0.0.1:${APP_UPSTREAM_PORT}:3000"
    environment:
      DATABASE_URL: postgresql://umami:${DATABASE_PASSWORD}@db:5432/umami
      DATABASE_TYPE: postgresql
      APP_SECRET: "${APP_SECRET}"
    depends_on:
      db:
        condition: service_healthy
  db:
    image: postgres:16-alpine
    restart: always
    environment:
      POSTGRES_DB: umami
      POSTGRES_USER: umami
      POSTGRES_PASSWORD: ${DATABASE_PASSWORD}
    volumes:
      - umami-db-data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U umami -d umami"]
      interval: 5s
      timeout: 5s
      retries: 10
volumes:
  umami-db-data:
EOF

bash "${SCRIPT_DIR}/domain.sh" "${DOMAIN}"
