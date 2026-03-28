#!/bin/bash

APP_NAME="signoz"
APP_DIR="/var/excloud/apps"
SCRIPT_DIR="/var/excloud/scripts"
APP_UPSTREAM_PORT="${EXC_APP_UPSTREAM_PORT:-8080}"

DOMAIN="${1}"

if [ -z "$DOMAIN" ]; then
  echo "Error: URL argument is required. Example:" >&2
  echo "domain.sh sub.example.com" >&2
  exit 1
fi

URL="https://${DOMAIN}"
COMPOSE_FILE="${APP_DIR}/signoz/deploy/docker/docker-compose.yaml"

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

source /var/excloud/scripts/caddy-setup.sh

# Signoz needs a custom Caddyfile with multi-route config
read -r -d '' SIGNOZ_CADDYFILE <<EOF
${URL} {
        reverse_proxy 127.0.0.1:${APP_UPSTREAM_PORT}
        handle_errors {
                root * ${APP_DIR}/${APP_NAME}/.excloud
                rewrite * /unavailable.html
                file_server
        }
}

${URL}:4317 {
        reverse_proxy h2c://127.0.0.1:44317
}

${URL}:4318 {
        reverse_proxy 127.0.0.1:44318
}
EOF

set_env "SIGNOZ_GLOBAL_EXTERNAL_URL" "${URL}" ".services.signoz.environment"
set_env "SIGNOZ_GLOBAL_INGESTION_URL" "${URL}" ".services.signoz.environment"
set_env "SIGNOZ_ALERTMANAGER_SIGNOZ_EXTERNAL_URL" "${URL}" ".services.signoz.environment"

if is_app_ready "$APP_DIR/$APP_NAME"; then
    docker compose -f $COMPOSE_FILE up -d --remove-orphans
    switch_domain "$DOMAIN" "$APP_UPSTREAM_PORT" "$APP_DIR/$APP_NAME" "$SIGNOZ_CADDYFILE"
else
    setup_initializing_page "$DOMAIN" "$APP_NAME" "$APP_DIR/$APP_NAME"
    docker compose -f $COMPOSE_FILE up -d --remove-orphans
    wait_and_switch_to_proxy "$DOMAIN" "$APP_UPSTREAM_PORT" "$APP_DIR/$APP_NAME" "$SIGNOZ_CADDYFILE" &
fi
