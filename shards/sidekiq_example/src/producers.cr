require "sidekiq"
require "./workers"

# This initializes the Client API with a default Redis connection to localhost:6379.
# See the Configuration page for how to point to a custom Redis location.
Sidekiq::Client.default_context = Sidekiq::Client::Context.new

# Now somewhere in your code you can create as many jobs as you want:
Sample::MyWorker.async.perform("world", 3_i64)
Sample::MyWorker.async.perform_in(100.seconds, "world perform_in", 3_i64)

tomorrow = Time.local + 1.day
Sample::MyWorker.async.perform_at(tomorrow, "world perform_at", 3_i64)
