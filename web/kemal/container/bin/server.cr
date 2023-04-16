#! /usr/bin/env crystal
# Starting web server
require "../config/*"
require "../src/tasks_web"

LOGGER.info &.emit("Starting server in...
  * Environment: #{Kemal.config.env}
  * Listening on http://0.0.0.0:#{Kemal.config.port}
Use Ctrl-C to stop", app_env: Kemal.config.env, app_port: Kemal.config.port)

Kemal.run
