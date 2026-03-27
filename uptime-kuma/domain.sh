#!/bin/bash

APP_NAME="uptime-kuma"
APP_DIR="/var/excloud/apps"
APP_UPSTREAM_PORT="${EXC_APP_UPSTREAM_PORT:-3001}"

DOMAIN="${1}"

if [ -z "${DOMAIN}" ]; then
  echo "Error: URL argument is required. Example:" >&2
  echo "domain.sh sub.example.com" >&2
  exit 1
fi

URL="https://${DOMAIN}"
COMPOSE_FILE="${APP_DIR}/${APP_NAME}/docker-compose.yml"

cat > /etc/caddy/Caddyfile <<EOF
${URL} {
        reverse_proxy 127.0.0.1:${APP_UPSTREAM_PORT}
}
EOF

echo "Caddyfile updated"

systemctl enable caddy
docker compose -f "${COMPOSE_FILE}" up -d --remove-orphans
systemctl reload caddy
