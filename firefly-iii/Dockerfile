# Upstream Firefly III release bundled with this add-on version.
ARG FIREFLY_VERSION=6.2.21
FROM fireflyiii/core:version-${FIREFLY_VERSION}

# Upstream runs as an unprivileged user; root is needed to install packages
# here and for run.sh to prepare /data at start-up.
USER root

RUN apt-get update \
    && apt-get install -y --no-install-recommends jq \
    && rm -rf /var/lib/apt/lists/*

# Home Assistant ingress passes the URL prefix in X-Ingress-Path; expose it
# to Laravel as X-Forwarded-Prefix so generated links keep the prefix.
RUN a2enmod headers \
    && printf '%s\n' \
        'SetEnvIf X-Ingress-Path "(.+)" INGRESS_PATH=$1' \
        'RequestHeader set X-Forwarded-Prefix "%{INGRESS_PATH}e" env=INGRESS_PATH' \
        > /etc/apache2/conf-available/ingress.conf \
    && a2enconf ingress

COPY run.sh /usr/local/bin/addon-run.sh
RUN chmod +x /usr/local/bin/addon-run.sh

ENTRYPOINT ["/usr/local/bin/addon-run.sh"]
CMD ["apache2-foreground"]
