require "redis"

pool_params = "?initial_pool_size=1&max_pool_size=10&checkout_timeout=10&retry_attempts=2&retry_delay=0.5&max_idle_pool_size=50"
uri = URI.parse("redis://localhost:6379/0#{pool_params}")
redis = Redis::Client.new uri

p! redis.set "foo", "bar", ex: 120.seconds
p! redis.get "foo" # => "bar"

p! redis.incr "counter" # => 1
p! redis.incr "counter" # => 2
p! redis.decr "counter" # => 1

# p! redis.del "foo", "counter" # => 2
p! redis.del "counter" # => 2

10.times do |i|
  puts "i: #{i}"
  spawn do
    puts "i fiber: #{i}"
    p! redis.set("fiber#{i}", "bar", ex: 60)
    p! redis.get("fiber#{i}") # => "bar"
  end
end

puts "Before yield"
Fiber.yield
puts "After yield"

