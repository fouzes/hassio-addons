#!/bin/bash
# Wrapper that maps Home Assistant add-on options to Actual Budget settings
# and then hands over to the upstream command.
set -euo pipefail

OPTIONS=/data/options.json
opt() { jq -r "$1 // empty" "$OPTIONS"; }

# Budget files and the server database live in the add-on data directory.
export ACTUAL_DATA_DIR=/data
export ACTUAL_PORT=5006

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
fi

exec "$@"
