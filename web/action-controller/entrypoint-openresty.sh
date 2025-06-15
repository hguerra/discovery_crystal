#!/bin/bash

# Load .env
# set -a
# source .env
# set +a

# Start process
/usr/src/app/api/app -b "0.0.0.0" "-p" "3000" &
/usr/local/openresty/bin/openresty -g "daemon off;" -c /usr/local/openresty/nginx/conf/nginx.conf &

# Wait for any process to exit
wait -n

# Exit with status of process that exited first
exit $?
