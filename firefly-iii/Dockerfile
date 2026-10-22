# Upstream Firefly III release bundled with this add-on version.
ARG FIREFLY_VERSION=6.2.21
FROM fireflyiii/core:version-${FIREFLY_VERSION}

# Upstream runs as an unprivileged user; root is needed to install packages
# here and for run.sh to prepare /data at start-up.
USER root

RUN apt-get update \
    && apt-get install -y --no-install-recommends jq \
    && rm -rf /var/lib/apt/lists/*

# Home Assistant ingress passes the URL prefix in X-Ingress-Path. Render the
# upstream nginx site template ahead of time with the image defaults and add
# X-Forwarded-Prefix (which Firefly III trusts) so generated links keep it.
RUN sed -e 's#\$NGINX_WEBROOT#/var/www/html/public#' \
        -e 's#\$NGINX_FASTCGI_BUFFERS#8 8k#' \
        -e 's#\$NGINX_FASTCGI_BUFFER_SIZE#8k#' \
        -e 's#\$PHP_MAX_EXECUTION_TIME#300#' \
        /etc/nginx/site-opts.d/http.conf.template \
        > /etc/nginx/site-opts.d/http.conf \
    && sed -i '/fastcgi_read_timeout 300;/a\    fastcgi_param  HTTP_X_FORWARDED_PREFIX $http_x_ingress_path;' \
        /etc/nginx/site-opts.d/http.conf \
    && grep -q HTTP_X_FORWARDED_PREFIX /etc/nginx/site-opts.d/http.conf \
    && ! grep -q '\$[A-Z_]\+' /etc/nginx/site-opts.d/http.conf

# storage/upload is a VOLUME in the upstream image and cannot be replaced, so
# let the upload disk root be configured and keep it under /data instead.
RUN sed -i "s#'root'   => storage_path('upload'),#'root'   => env('UPLOAD_PATH', storage_path('upload')),#" \
        /var/www/html/config/filesystems.php \
    && grep -q UPLOAD_PATH /var/www/html/config/filesystems.php \
    && command -v setpriv

COPY run.sh /usr/local/bin/addon-run.sh
RUN chmod +x /usr/local/bin/addon-run.sh

ENTRYPOINT ["/usr/local/bin/addon-run.sh"]
CMD ["/init"]
