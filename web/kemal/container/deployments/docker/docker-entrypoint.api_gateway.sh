#!/usr/bin/env bash

# Ref:
# https://docs.docker.com/config/containers/multi-service_container/
# https://devcenter.heroku.com/articles/deploying-rails-applications-with-the-puma-web-server#recommended-default-puma-process-and-thread-configuration

# Load .env
set -a
source .env
set +a

# Start process
APP_ENV=production APP_PORT=3001 ./server &
APP_ENV=production APP_PORT=3002 ./server &
APP_ENV=production APP_PORT=3003 ./server &
bash /docker-entrypoint.sh kong docker-start &

# Wait for any process to exit
wait -n

# Exit with status of process that exited first
exit $?