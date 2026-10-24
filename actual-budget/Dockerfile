# Upstream Actual Budget release bundled with this add-on version.
ARG ACTUAL_VERSION=26.10.0
FROM actualbudget/actual-server:${ACTUAL_VERSION}

# The upstream image runs as root by default and has tini as its init; jq is
# only needed to read the add-on options in run.sh.
RUN apt-get update \
    && apt-get install -y --no-install-recommends jq \
    && rm -rf /var/lib/apt/lists/*

COPY run.sh /usr/local/bin/addon-run.sh
RUN chmod +x /usr/local/bin/addon-run.sh

ENTRYPOINT ["/usr/bin/tini", "-g", "--", "/usr/local/bin/addon-run.sh"]
CMD ["node", "build/app.js"]
