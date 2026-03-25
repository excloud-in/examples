#!/bin/bash

APP_NAME="signoz"
APP_DIR="/var/excloud/apps"
SCRIPT_DIR="/var/excloud/scripts"
DOMAIN="${1}"
if [ -z "$DOMAIN" ]; then
  echo "Error: URL argument is required. Example:" >&2
  echo "domain-change.sh sub.example.com" >&2
  exit 1
fi
SIGNOZ_DIR="${APP_DIR}/signoz"
COMPOSE_FILE="${SIGNOZ_DIR}/deploy/docker/docker-compose.yaml"
OTEL_SERVICE_PATH='.services["otel-collector"].ports'
SIGNOZ_SERVICE_PATH=".services.signoz.ports"

mkdir -p "${APP_DIR}"
mkdir -p "${SCRIPT_DIR}"

apt-get install -y caddy yq

rm -rf ${SIGNOZ_DIR}
git clone -b main https://github.com/SigNoz/signoz.git ${SIGNOZ_DIR}
cd ${SIGNOZ_DIR}/deploy/docker

bash "${SCRIPT_DIR}/domain-signoz.sh" "${DOMAIN}"

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

set_port "127.0.0.1:44317:4317" "$OTEL_SERVICE_PATH"
set_port "127.0.0.1:44318:4318" "$OTEL_SERVICE_PATH"
set_port "127.0.0.1:8080:8080" "$SIGNOZ_SERVICE_PATH"

docker compose -f $COMPOSE_FILE up -d --remove-orphans
