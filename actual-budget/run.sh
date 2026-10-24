#!/bin/bash
# Wrapper that maps Home Assistant add-on options to Actual Budget settings,
# then runs the upstream command next to the nginx proxy for ingress.
set -euo pipefail

OPTIONS=/data/options.json
opt() { jq -r "$1 // empty" "$OPTIONS"; }

# Budget files and the server database live in the add-on data directory.
export ACTUAL_DATA_DIR=/data
export ACTUAL_PORT=5006
# nginx (ingress) connects from the loopback address; trust it for the client
# address, in addition to Actual's default private ranges.
export ACTUAL_TRUSTED_PROXIES="127.0.0.1/32,::1/128,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,fc00::/7"

# Actual Budget only works in a secure context (HTTPS or localhost), so serve
# HTTPS directly from the Home Assistant certificates when asked to.
if [ "$(opt .ssl)" = "true" ]; then
    CERT_FILE="/ssl/$(opt .certfile)"
    KEY_FILE="/ssl/$(opt .keyfile)"
    for file in "$CERT_FILE" "$KEY_FILE"; do
        if [ ! -r "$file" ]; then
            echo "SSL is enabled but $file does not exist or is not readable." >&2
            exit 1
        fi
    done
    export ACTUAL_HTTPS_CERT="$CERT_FILE"
    export ACTUAL_HTTPS_KEY="$KEY_FILE"
    UPSTREAM=https://127.0.0.1:5006
else
    UPSTREAM=http://127.0.0.1:5006
fi
echo "set \$actual_upstream $UPSTREAM;" > /run/addon-upstream.conf
mkdir -p /tmp/nginx

# Run Actual and the ingress proxy side by side; if either stops, stop the
# other and exit so the Supervisor restarts the add-on.
"$@" &
ACTUAL_PID=$!
nginx -e /dev/stderr -c /etc/addon-nginx.conf &
NGINX_PID=$!
trap 'kill "$ACTUAL_PID" "$NGINX_PID" 2>/dev/null || true' TERM INT

set +e
wait -n "$ACTUAL_PID" "$NGINX_PID"
STATUS=$?
kill "$ACTUAL_PID" "$NGINX_PID" 2>/dev/null
wait
exit "$STATUS"
