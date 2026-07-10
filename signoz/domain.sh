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
SIGNOZ_DIR="${APP_DIR}/${APP_NAME}"
STATE_DIR="${SIGNOZ_DIR}/.excloud"
JWT_SECRET_FILE="${STATE_DIR}/jwt-secret"
COMPOSE_FILE="${SIGNOZ_DIR}/pours/deployment/compose.yaml"

if [ ! -f "${JWT_SECRET_FILE}" ]; then
    echo "SigNoz JWT secret not found: ${JWT_SECRET_FILE}" >&2
    exit 1
fi

JWT_SECRET=$(cat "${JWT_SECRET_FILE}")

cd "${SIGNOZ_DIR}"
cat > "${SIGNOZ_DIR}/casting.yaml" <<EOF
apiVersion: v1alpha1
kind: Installation
metadata:
  name: signoz
spec:
  deployment:
    flavor: compose
    mode: docker
  signoz:
    spec:
      env:
        SIGNOZ_TOKENIZER_JWT_SECRET: ${JWT_SECRET}
        SIGNOZ_GLOBAL_EXTERNAL__URL: ${URL}
        SIGNOZ_GLOBAL_INGESTION__URL: ${URL}
        SIGNOZ_ALERTMANAGER_SIGNOZ_EXTERNAL__URL: ${URL}
  patches:
    - target: deployment/compose.yaml
      operations:
        - op: replace
          path: /services/ingester/ports
          value:
            - "127.0.0.1:44317:4317"
            - "127.0.0.1:44318:4318"
        - op: replace
          path: /services/signoz-signoz-0/ports
          value:
            - "127.0.0.1:${APP_UPSTREAM_PORT}:8080"
EOF

foundryctl forge -f "${SIGNOZ_DIR}/casting.yaml"

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

if is_app_ready "$APP_DIR/$APP_NAME"; then
    docker compose -f "$COMPOSE_FILE" up -d --remove-orphans
    switch_domain "$DOMAIN" "$APP_UPSTREAM_PORT" "$APP_DIR/$APP_NAME" "$SIGNOZ_CADDYFILE"
else
    setup_initializing_page "$DOMAIN" "$APP_NAME" "$APP_DIR/$APP_NAME"
    docker compose -f "$COMPOSE_FILE" up -d --remove-orphans
    wait_and_switch_to_proxy "$DOMAIN" "$APP_UPSTREAM_PORT" "$APP_DIR/$APP_NAME" "$SIGNOZ_CADDYFILE" &
fi
