# Upstream Firefly III release bundled with this add-on version.
ARG FIREFLY_VERSION=6.2.21
FROM fireflyiii/core:version-${FIREFLY_VERSION}

# Upstream runs as an unprivileged user; root is needed to install packages
# here and for run.sh to prepare /data at start-up.
USER root

RUN apt-get update \
    && apt-get install -y --no-install-recommends jq \
    && rm -rf /var/lib/apt/lists/*

COPY run.sh /usr/local/bin/addon-run.sh
RUN chmod +x /usr/local/bin/addon-run.sh

ENTRYPOINT ["/usr/local/bin/addon-run.sh"]
CMD ["apache2-foreground"]
