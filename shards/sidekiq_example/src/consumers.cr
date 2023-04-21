require "sidekiq/cli"
require "./workers"

# REDIS_PROVIDER=redis://:password@redis.example.com/0
cli = Sidekiq::CLI.new
server = cli.configure do |config|
  # middleware would be added here
end

cli.run(server)
