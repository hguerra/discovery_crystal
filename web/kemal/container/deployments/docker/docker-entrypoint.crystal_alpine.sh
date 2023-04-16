#!/usr/bin/env sh

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

# Wait for any process to exit
wait -n

# Exit with status of process that exited first
exit $?
