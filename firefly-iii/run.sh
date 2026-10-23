#!/bin/bash
# Wrapper that maps Home Assistant add-on options to Firefly III settings,
# persists data under /data and then hands over to the upstream entrypoint.
set -euo pipefail

OPTIONS=/data/options.json
opt() { jq -r "$1 // empty" "$OPTIONS"; }

# --- Persistent storage -------------------------------------------------
STORAGE=/data/storage
mkdir -p "$STORAGE"/{app,build,database,debugbar,export,logs,upload} \
         "$STORAGE"/framework/{cache/data,sessions,views}
# The upstream image keeps storage/upload as a VOLUME mount point, which cannot
# be replaced, so link every other entry and point the upload disk at /data.
for name in app build database debugbar export framework logs; do
    rm -rf "/var/www/html/storage/$name"
    ln -s "$STORAGE/$name" "/var/www/html/storage/$name"
done
for name in oauth-private.key oauth-public.key; do
    ln -sf "$STORAGE/$name" "/var/www/html/storage/$name"
done
export UPLOAD_PATH="$STORAGE/upload"

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
# Ingress requests arrive from the Supervisor proxy, so trust it by default.
export TRUSTED_PROXIES="$(opt .trusted_proxies)"
: "${TRUSTED_PROXIES:=**}"
export TRUSTED_PROXIES
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

# Upstream runs as www-data; drop root now that /data is prepared. PHP-FPM
# reopens /proc/self/fd/2 for its log, which fails for www-data when stderr is
# owned by root. Route all output through a world-writable FIFO instead; a
# root-owned reader forwards it to the real container output. The FIFO stays
# root-owned because fs.protected_fifos refuses O_CREAT opens of FIFOs owned by
# another user in sticky directories such as /tmp.
LOG_FIFO=/run/addon-log.fifo
rm -f "$LOG_FIFO"
mkfifo -m 666 "$LOG_FIFO"
cat "$LOG_FIFO" &

export HOME=/var/www
exec setpriv --reuid=www-data --regid=www-data --init-groups \
    docker-php-serversideup-entrypoint "$@" >"$LOG_FIFO" 2>&1
