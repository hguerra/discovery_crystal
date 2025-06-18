# -------- Stage 1: Build backend
FROM crystallang/crystal:1.16 AS backend

WORKDIR /opt/my-api
COPY shard.yml shard.lock* ./
RUN shards install

COPY src/ ./src/
RUN crystal build src/app.cr -o /usr/bin/my-api --release

# -------- Stage 2: nginx + s6-overlay
FROM nginx:1.27-bookworm AS nginx_s6

ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2 \
    S6_CMD_WAIT_FOR_SERVICES=1 \
    S6_SERVICES_GRACETIME=5000

# Install s6-overlay and create non-root user
RUN apt-get update && apt-get install -y --no-install-recommends curl xz-utils \
  && curl -L https://github.com/just-containers/s6-overlay/releases/latest/download/s6-overlay-noarch.tar.xz | tar -C / -Jx \
  && curl -L https://github.com/just-containers/s6-overlay/releases/latest/download/s6-overlay-x86_64.tar.xz | tar -C / -Jx \
  && groupadd -r appuser && useradd -r -g appuser appuser \
  && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Copy configuration files first (better cache)
COPY rootfs/ /

# Set proper permissions for all service scripts
RUN chmod +x /etc/services.d/nginx/run \
  && chmod +x /etc/services.d/crystal-api-1/run \
  && chmod +x /etc/services.d/crystal-api-2/run \
  && chmod +x /etc/services.d/crystal-api-3/run \
  && mkdir -p /run/secrets && chown appuser:appuser /run/secrets

# Copy static files
COPY --chown=appuser:appuser www/public/ /var/www/html/public/
COPY --chown=appuser:appuser www/app/dist/ /var/www/html/app/
COPY --chown=appuser:appuser www/app/public/* /var/www/html/public
RUN chown -R appuser:appuser /var/www/html /var/log/nginx /var/cache/nginx

# -------- Stage 3: Final image
FROM nginx_s6 AS final

# Copy binary from backend stage and set permissions
COPY --from=backend /usr/bin/my-api /usr/bin/my-api
RUN chown appuser:appuser /usr/bin/my-api && chmod +x /usr/bin/my-api

# Switch to non-root user
USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080/api/health || exit 1

ENTRYPOINT ["/init"]
