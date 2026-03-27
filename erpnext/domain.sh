#!/bin/bash

APP_UPSTREAM_PORT="${EXC_APP_UPSTREAM_PORT:-8080}"
DOMAIN="${1}"

if [ -z "${DOMAIN}" ]; then
  echo "Error: URL argument is required. Example:" >&2
  echo "domain.sh sub.example.com" >&2
  exit 1
fi

cat > /etc/caddy/Caddyfile <<EOF
https://${DOMAIN} {
        reverse_proxy 127.0.0.1:${APP_UPSTREAM_PORT}
}
EOF

echo "Caddyfile updated"

systemctl enable caddy
systemctl reload caddy
