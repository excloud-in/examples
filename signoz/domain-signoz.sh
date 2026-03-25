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

set_env "SIGNOZ_GLOBAL_EXTERNAL_URL" "${URL}" ".services.signoz.environment"
set_env "SIGNOZ_GLOBAL_INGESTION_URL" "${URL}" ".services.signoz.environment"

cat > /etc/caddy/Caddyfile << EOF
${URL} {
        reverse_proxy localhost:8080
}

${URL}:4317 {
        reverse_proxy h2c://localhost:44317
}

${URL}:4318 {
        reverse_proxy localhost:44318
}
EOF

echo "Caddyfile updated"

docker compose -f $COMPOSE_FILE up -d --remove-orphans
systemctl reload caddy
