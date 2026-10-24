# Upstream Actual Budget release bundled with this add-on version.
ARG ACTUAL_VERSION=26.10.0
FROM actualbudget/actual-server:${ACTUAL_VERSION}

# The upstream image runs as root by default and has tini as its init. jq reads
# the add-on options in run.sh; nginx is the ingress front door.
RUN apt-get update \
    && apt-get install -y --no-install-recommends jq nginx \
    && rm -rf /var/lib/apt/lists/*

# The web client is built for the site root, which Home Assistant ingress does
# not have. Rewrite it to resolve its addresses against the page's <base> tag;
# the build fails if upstream changed the code the patch is written for, so
# review patches/patch-web.mjs whenever ACTUAL_VERSION changes.
COPY patches /tmp/patches
RUN node /tmp/patches/patch-web.mjs \
        /app/node_modules/@actual-app/web/build /tmp/patches/ha-base-path.js \
    && rm -rf /tmp/patches

COPY nginx/nginx.conf /etc/addon-nginx.conf

COPY run.sh /usr/local/bin/addon-run.sh
RUN chmod +x /usr/local/bin/addon-run.sh

# Home Assistant shows the add-on as unhealthy when either web server stops
# accepting connections: Actual Budget (5006) or the ingress proxy (8099).
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
    CMD ["bash", "-c", "exec 3<>/dev/tcp/127.0.0.1/5006 && exec 4<>/dev/tcp/127.0.0.1/8099"]

ENTRYPOINT ["/usr/bin/tini", "-g", "--", "/usr/local/bin/addon-run.sh"]
CMD ["node", "app.js"]
