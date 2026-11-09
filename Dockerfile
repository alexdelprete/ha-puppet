# syntax=docker/dockerfile:1
FROM node:22-bookworm-slim@sha256:5ec23b7c622b00547753bc6ffd78085dd868a68aeb41c8e0a1418f033e13d96d

ENV DEBIAN_FRONTEND=noninteractive \
    NODE_ENV=production \
    PUPPETEER_SKIP_DOWNLOAD=true \
    TZ=Etc/UTC

RUN apt-get update \
    && apt-get install -y \
        chromium \
        fonts-noto-cjk \
        fonts-noto-color-emoji \
        tini \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY upstream/puppet/ha-puppet/package.json upstream/puppet/ha-puppet/package-lock.json ./
RUN npm ci --omit=dev \
    && npm cache clean --force

COPY upstream/puppet/ha-puppet/ ./
COPY entrypoint.mjs ./entrypoint.mjs

RUN rm -f options-dev.json \
    && install -d -o node -g node -m 0700 /data

USER node

EXPOSE 10000

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --start-interval=2s --retries=3 \
    CMD ["node", "-e", "fetch('http://127.0.0.1:10000/tailwind.css').then(r => process.exit(r.ok ? 0 : 1), () => process.exit(1))"]

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["node", "entrypoint.mjs"]

ARG UPSTREAM_REVISION=unknown
ARG UPSTREAM_VERSION=unknown
ARG IMAGE_VERSION=dev

ENV HA_PUPPET_VERSION=${IMAGE_VERSION} \
    PUPPET_VERSION=${UPSTREAM_VERSION}

LABEL org.opencontainers.image.title="ha-puppet" \
      org.opencontainers.image.description="Standalone container image of balloob's Puppet, the Home Assistant dashboard screenshot service" \
      org.opencontainers.image.source="https://github.com/alexdelprete/ha-puppet" \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.version="${IMAGE_VERSION}" \
      io.github.alexdelprete.ha-puppet.upstream.source="https://github.com/balloob/home-assistant-addons" \
      io.github.alexdelprete.ha-puppet.upstream.revision="${UPSTREAM_REVISION}" \
      io.github.alexdelprete.ha-puppet.upstream.version="${UPSTREAM_VERSION}"
