#!/bin/bash

APP_NAME="signoz"
APP_DIR="/var/excloud/apps"
SCRIPT_DIR="/var/excloud/scripts"
POSTGRES_DSN="postgres://postgres:your_password@localhost:5432/signoz?sslmode=disable"
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
STATE_DIR="${SIGNOZ_DIR}/.excloud"
COMPOSE_FILE="${SIGNOZ_DIR}/deploy/docker/docker-compose.yaml"
OTEL_SERVICE_PATH='.services["otel-collector"].ports'
SIGNOZ_SERVICE_PATH=".services.signoz.ports"



if git -C "${SIGNOZ_DIR}" rev-parse 2>/dev/null; then
    echo "Git repo exists"
else
    rm -rf "${SIGNOZ_DIR}"
    git clone -b main https://github.com/SigNoz/signoz.git "${SIGNOZ_DIR}"
fi

mkdir -p "${STATE_DIR}"
JWT_SECRET_FILE="${STATE_DIR}/jwt-secret"

if [ -f "${JWT_SECRET_FILE}" ]; then
    JWT_SECRET=$(cat "${JWT_SECRET_FILE}")
else
    echo "${JWT_SECRET}" > "${JWT_SECRET_FILE}"
fi

cd "${SIGNOZ_DIR}/deploy/docker"

set_port() {
    local port_pair="$1"
    local service_path="$2"
    local port_num="${port_pair##*:}"

    if yq "${service_path}[] | select(. == ${port_num} or (type == \"string\" and test(\"${port_num}:${port_num}\")))" "$COMPOSE_FILE" | grep -q .; then
        yq -yi "(${service_path}[] | select(. == ${port_num} or (type == \"string\" and test(\"${port_num}:${port_num}\")))) = \"${port_pair}\"" "$COMPOSE_FILE"
        echo "Replaced: ${port_pair}"
    else
        yq -yi "${service_path} += [\"${port_pair}\"]" "$COMPOSE_FILE"
        echo "Added: ${port_pair}"
    fi
}

set_env() {
    local key="$1"
    local value="$2"
    local service_path="$3"
    local env_pair="${key}=${value}"

    if yq "${service_path}" "$COMPOSE_FILE" | grep -q "${key}="; then
        yq -yi "(${service_path}[] | select(type == \"string\" and test(\"^${key}=\"))) = \"${env_pair}\"" "$COMPOSE_FILE"
        echo "Replaced: ${env_pair}"
    else
        yq -yi "${service_path} += [\"${env_pair}\"]" "$COMPOSE_FILE"
        echo "Added: ${env_pair}"
    fi
}

set_port "127.0.0.1:44317:4317" "$OTEL_SERVICE_PATH"
set_port "127.0.0.1:44318:4318" "$OTEL_SERVICE_PATH"
set_port "127.0.0.1:${APP_UPSTREAM_PORT}:8080" "$SIGNOZ_SERVICE_PATH"
set_env "SIGNOZ_TOKENIZER_JWT_SECRET" "${JWT_SECRET}" ".services.signoz.environment"
# TODO Add support for postgres DSN
# set_env "SIGNOZ_SQLSTORE_PROVIDER" "${JWT_SECRET}" ".services.signoz.environment"
# set_env "SIGNOZ_SQLSTORE_POSTGRES_DSN" "${POSTGRES_DSN}" ".services.signoz.environment"


bash "${SCRIPT_DIR}/domain.sh" "${DOMAIN}"
