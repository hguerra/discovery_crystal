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

RUN apt-get update && apt-get install -y curl xz-utils \
  && curl -L https://github.com/just-containers/s6-overlay/releases/latest/download/s6-overlay-noarch.tar.xz | tar -C / -Jx \
  && curl -L https://github.com/just-containers/s6-overlay/releases/latest/download/s6-overlay-x86_64.tar.xz | tar -C / -Jx \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY rootfs/ /

RUN chmod +x /etc/services.d/app/run /etc/services.d/nginx/run

COPY www/ /var/www/html/

# -------- Stage 3: Final image
FROM nginx_s6 AS final

COPY --from=backend /usr/bin/my-api /usr/bin/my-api

ENTRYPOINT ["/init"]
