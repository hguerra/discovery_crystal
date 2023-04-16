#! /usr/bin/env crystal
require "sentry"

sentry = [
  Sentry::ProcessRunner.new(
    display_name: "Server",
    build_command: "crystal build -o ./tmp/main bin/server.cr",
    run_command: "./tmp/main",
    files: ["./config/**", "./src/**/*"]
  ),
]

# Execute runners in separate threads
sentry.each { |s| spawn { s.run } }

begin
  sleep
rescue
  sentry.each(&.kill)
end
