# Upstream Firefly III release bundled with this add-on version.
ARG FIREFLY_VERSION=6.7.9
FROM fireflyiii/core:version-${FIREFLY_VERSION}

# Upstream runs as an unprivileged user; root is needed to install packages
# here and for run.sh to prepare /data at start-up.
USER root

RUN apt-get update \
    && apt-get install -y --no-install-recommends jq \
    && rm -rf /var/lib/apt/lists/*

# Upstream renders its nginx templates when the container starts, writing into
# /etc/nginx as www-data, which fails under the add-on's AppArmor profile (and
# is needless work on every start). Render them now exactly as the upstream
# entrypoint does, with the image defaults, and keep the real-IP handling of
# trusted proxies switched off: the upstream default trusts a client-supplied
# CF-Connecting-IP header from private networks, which would let LAN clients
# fake the ingress address checked below. Ingress connects over IPv4, so the
# IPv6 listeners are dropped; nginx would not start on hosts without IPv6.
ENV TRUSTED_PROXY=off
RUN vars=$(env | grep -E '^(PHP_|NGINX_|SSL_|LOG_|APACHE_|HEALTHCHECK_PATH|TRUSTED_PROXY)' \
        | cut -d= -f1 | awk '{printf "${%s},",$1}' | sed 's/,$//') \
    && envsubst "$vars" < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf \
    && envsubst "$vars" < /etc/nginx/site-opts.d/http.conf.template > /etc/nginx/site-opts.d/http.conf \
    && envsubst "$vars" < /etc/nginx/site-opts.d/https.conf.template > /etc/nginx/site-opts.d/https.conf \
    && envsubst "$vars" < /etc/nginx/sites-available/ssl-full.template > /etc/nginx/sites-available/ssl-full \
    && sed -i '/listen \[::\]:/d' /etc/nginx/nginx.conf /etc/nginx/site-opts.d/http.conf \
        /etc/nginx/site-opts.d/https.conf /etc/nginx/sites-available/ssl-full \
    && ln -s /etc/nginx/sites-available/ssl-off /etc/nginx/conf.d/default.conf

# Home Assistant ingress passes the URL prefix in X-Ingress-Path. Add
# X-Forwarded-Prefix (which Firefly III trusts) to the rendered site so generated
# links keep it, and only let the ingress proxy connect: the user it passes in
# X-Remote-User-Name becomes the Firefly III user.
RUN printf '%s\n' 'allow 172.30.32.2;' 'allow 127.0.0.1;' 'allow ::1;' 'deny all;' \
        > /etc/nginx/addon-access.conf \
    && printf '%s\n' \
        'if ($http_x_remote_user_name = "") { return 403; }' \
        'fastcgi_param REMOTE_USER "$http_x_remote_user_name@homeassistant.local";' \
        > /etc/nginx/addon-auth.conf \
    && sed -i \
        -e '/server_name _;/a\    include /etc/nginx/addon-access.conf;' \
        -e '/fastcgi_read_timeout 300;/a\    fastcgi_param  HTTP_X_FORWARDED_PREFIX $http_x_ingress_path;' \
        -e '/fastcgi_read_timeout 300;/a\    include /etc/nginx/addon-auth.conf;' \
        /etc/nginx/site-opts.d/http.conf \
    && grep -q HTTP_X_FORWARDED_PREFIX /etc/nginx/site-opts.d/http.conf \
    && grep -q addon-access.conf /etc/nginx/site-opts.d/http.conf \
    && grep -q addon-auth.conf /etc/nginx/site-opts.d/http.conf \
    && ! grep -q '\$[{A-Z_]' /etc/nginx/nginx.conf /etc/nginx/site-opts.d/http.conf

# storage/upload is a VOLUME in the upstream image and cannot be replaced, so
# let the upload disk root be configured and keep it under /data instead.
RUN sed -i "s#'root'   => storage_path('upload'),#'root'   => env('UPLOAD_PATH', storage_path('upload')),#" \
        /var/www/html/config/filesystems.php \
    && grep -q UPLOAD_PATH /var/www/html/config/filesystems.php \
    && command -v setpriv

COPY run.sh /usr/local/bin/addon-run.sh
RUN chmod +x /usr/local/bin/addon-run.sh

# Home Assistant shows the add-on as unhealthy when the web server stops
# accepting connections.
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
    CMD ["bash", "-c", "exec 3<>/dev/tcp/localhost/8080"]

ENTRYPOINT ["/usr/local/bin/addon-run.sh"]
CMD ["/init"]
