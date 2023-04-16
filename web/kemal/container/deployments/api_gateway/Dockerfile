FROM kong:3.2.2-ubuntu

USER root

# https://docs.konghq.com/hub/yesinteractive/kong-jwt2header
# https://github.com/yesinteractive/kong-jwt2header
RUN luarocks install kong-jwt2header

# https://docs.konghq.com/hub/seifchen/kong-path-allow
RUN luarocks install kong-path-allow

# https://github.com/ligreman/kong-proxy-cache-redis-cluster-plugin
# Plugins dir: /usr/local/share/lua/5.1/kong/plugins
RUN git clone https://github.com/ligreman/kong-proxy-cache-redis-cluster-plugin.git \
    && cd kong-proxy-cache-redis-cluster-plugin \
    && luarocks make \
    && cd /etc \
    && rm -rf /kong-proxy-cache-redis-cluster-plugin \
    && chown -R kong:kong /usr/local/share/lua/5.1/kong/plugins/proxy-cache-redis-cluster

RUN mkdir -p /opt/kong
COPY kong.yaml /opt/kong/kong.yaml
RUN chown -R kong:kong /opt/kong

USER kong

ENV KONG_DATABASE="off"
ENV KONG_PROXY_LISTEN="0.0.0.0:8080"
ENV KONG_ADMIN_LISTEN="0.0.0.0:8001"
ENV KONG_ADMIN_ACCESS_LOG="off"
ENV KONG_ADMIN_ERROR_LOG="/dev/stderr"
ENV KONG_PROXY_ACCESS_LOG="off"
ENV KONG_PROXY_ERROR_LOG="/dev/stderr"
ENV KONG_DECLARATIVE_CONFIG="/opt/kong/kong.yaml"
ENV KONG_PLUGINS="bundled,kong-jwt2header,kong-path-allow,proxy-cache-redis-cluster"

# Nginx Directives
# https://docs.konghq.com/gateway/latest/reference/nginx-directives
ENV KONG_NGINX_PROXY_GZIP="on"
ENV KONG_NGINX_PROXY_GZIP_DISABLE="msie6"
ENV KONG_NGINX_PROXY_GZIP_VARY="on"
ENV KONG_NGINX_PROXY_GZIP_PROXIED="any"
ENV KONG_NGINX_PROXY_GZIP_COMP_LEVEL="6"
ENV KONG_NGINX_PROXY_GZIP_BUFFERS="16 8k"
ENV KONG_NGINX_PROXY_GZIP_HTTP_VERSION="1.1"
ENV KONG_NGINX_PROXY_GZIP_MIN_LENGTH="256"
ENV KONG_NGINX_PROXY_GZIP_TYPES="application/atom+xml application/geo+json application/javascript application/x-javascript application/json application/ld+json application/manifest+json application/rdf+xml application/rss+xml application/xhtml+xml application/xml font/eot font/otf font/ttf image/svg+xml text/css text/javascript text/plain text/xml"
ENV KONG_NGINX_HTTP_LUA_SHARED_DICT="redis_cluster_slot_locks 100k"

EXPOSE 8080
STOPSIGNAL SIGTERM
