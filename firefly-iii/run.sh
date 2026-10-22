#!/bin/bash
# Wrapper that maps Home Assistant add-on options to Firefly III settings,
# persists data under /data and then hands over to the upstream entrypoint.
set -euo pipefail

OPTIONS=/data/options.json
opt() { jq -r "$1 // empty" "$OPTIONS"; }

# --- Persistent storage -------------------------------------------------
STORAGE=/data/storage
mkdir -p "$STORAGE"/{app,database,export,logs,upload} \
         "$STORAGE"/framework/{cache/data,sessions,views}
rm -rf /var/www/html/storage
ln -s "$STORAGE" /var/www/html/storage

# --- Application key (generated once, then reused) ----------------------
APP_KEY="$(opt .app_key)"
if [ -z "$APP_KEY" ]; then
    KEY_FILE=/data/app_key
    if [ ! -s "$KEY_FILE" ]; then
        echo "base64:$(head -c 32 /dev/urandom | base64)" > "$KEY_FILE"
        chmod 600 "$KEY_FILE"
    fi
    APP_KEY="$(cat "$KEY_FILE")"
fi
export APP_KEY

# --- General settings ---------------------------------------------------
export SITE_OWNER="$(opt .site_owner)"
export TZ="$(opt .timezone)"
export DEFAULT_LANGUAGE="$(opt .default_language)"
export TRUSTED_PROXIES="$(opt .trusted_proxies)"
export LOG_LEVEL="$(opt .log_level)"
export APP_ENV=production
export LOG_CHANNEL=stack
export APP_LOG_LEVEL="$LOG_LEVEL"

# --- Database -----------------------------------------------------------
DB_TYPE="$(opt .database.type)"
if [ "$DB_TYPE" = "mysql" ]; then
    export DB_CONNECTION=mysql
    export DB_HOST="$(opt .database.host)"
    export DB_PORT="$(opt .database.port)"
    export DB_DATABASE="$(opt .database.name)"
    export DB_USERNAME="$(opt .database.username)"
    export DB_PASSWORD="$(opt .database.password)"
else
    export DB_CONNECTION=sqlite
    export DB_DATABASE="$STORAGE/database/database.sqlite"
    touch "$DB_DATABASE"
fi

chown -R www-data:www-data "$STORAGE"

exec /usr/local/bin/entrypoint.sh "$@"
