#!/bin/bash
#
# Shared Caddy setup with initializing/unavailable pages.
#
# Usage in domain.sh:
#   source /var/excloud/scripts/caddy-setup.sh
#   setup_initializing_page "$DOMAIN" "$APP_NAME" "$APP_DIR/$APP_NAME"
#   ... start containers ...
#   wait_and_switch_to_proxy "$DOMAIN" "$APP_UPSTREAM_PORT" "$APP_DIR/$APP_NAME" &
#
# For apps with custom Caddyfile (e.g. signoz with multi-route), use:
#   write_loading_pages "$APP_NAME" "$APP_DIR/$APP_NAME"
#   setup_initializing_page "$DOMAIN" "$APP_NAME" "$APP_DIR/$APP_NAME"
#   ... start containers ...
#   wait_and_switch_to_proxy "$DOMAIN" "$APP_UPSTREAM_PORT" "$APP_DIR/$APP_NAME" "$CUSTOM_CADDYFILE_CONTENT" &

SCRIPT_DIR_CADDY="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

reload_or_start_caddy() {
    if systemctl is-active --quiet caddy; then
        systemctl reload caddy
    else
        systemctl enable --now caddy
    fi
}

write_loading_pages() {
    local app_name="$1"
    local app_dir="$2"

    local display_name
    display_name="$(echo "$app_name" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)}1')"

    mkdir -p "${app_dir}/.excloud"

    cp "${SCRIPT_DIR_CADDY}/initializing.html" "${app_dir}/.excloud/initializing.html"
    cp "${SCRIPT_DIR_CADDY}/unavailable.html" "${app_dir}/.excloud/unavailable.html"

    sed -i "s/APP_DISPLAY_NAME/${display_name}/g" "${app_dir}/.excloud/initializing.html"
    sed -i "s/APP_DISPLAY_NAME/${display_name}/g" "${app_dir}/.excloud/unavailable.html"
}

# Phase 1: Serve the initializing page immediately via Caddy file_server.
setup_initializing_page() {
    local domain="$1"
    local app_name="$2"
    local app_dir="$3"

    write_loading_pages "$app_name" "$app_dir"

    cat > /etc/caddy/Caddyfile <<EOF
https://${domain} {
        root * ${app_dir}/.excloud
        rewrite * /initializing.html
        file_server
}
EOF

    reload_or_start_caddy
    echo "Caddy serving initializing page for ${app_name}"
}

# Phase 2 (runs in background): Poll the upstream port, then switch Caddy to reverse_proxy.
# Accepts an optional 4th argument with custom Caddyfile content for apps like signoz.
wait_and_switch_to_proxy() {
    local domain="$1"
    local port="$2"
    local app_dir="$3"
    local custom_caddyfile="${4:-}"

    # Wait for the app to respond (up to 20 minutes)
    local start_time
    start_time="$(date +%s)"
    while ! curl -fsS -o /dev/null "http://127.0.0.1:${port}" 2>/dev/null; do
        if [ $(( $(date +%s) - start_time )) -ge 1200 ]; then
            echo "App did not become ready within 20 minutes" >&2
            break
        fi
        sleep 5
    done

    # Switch to reverse proxy with handle_errors for unavailable page
    if [ -n "$custom_caddyfile" ]; then
        echo "$custom_caddyfile" > /etc/caddy/Caddyfile
    else
        cat > /etc/caddy/Caddyfile <<EOF
https://${domain} {
        reverse_proxy 127.0.0.1:${port}
        handle_errors {
                root * ${app_dir}/.excloud
                rewrite * /unavailable.html
                file_server
        }
}
EOF
    fi

    touch "${app_dir}/.excloud/.ready"
    reload_or_start_caddy
    echo "App is ready — Caddy switched to reverse proxy"
}

# Quick domain swap for an already-running app. Skips the initializing page
# and background watcher — just updates the Caddyfile and reloads.
# Accepts an optional 4th argument with custom Caddyfile content.
switch_domain() {
    local domain="$1"
    local port="$2"
    local app_dir="$3"
    local custom_caddyfile="${4:-}"

    write_loading_pages "$(basename "$app_dir")" "$app_dir"

    if [ -n "$custom_caddyfile" ]; then
        echo "$custom_caddyfile" > /etc/caddy/Caddyfile
    else
        cat > /etc/caddy/Caddyfile <<EOF
https://${domain} {
        reverse_proxy 127.0.0.1:${port}
        handle_errors {
                root * ${app_dir}/.excloud
                rewrite * /unavailable.html
                file_server
        }
}
EOF
    fi

    reload_or_start_caddy
    echo "Domain switched to ${domain}"
}

# Returns 0 if the app has completed first-time setup, 1 otherwise.
is_app_ready() {
    local app_dir="$1"
    [ -f "${app_dir}/.excloud/.ready" ]
}
