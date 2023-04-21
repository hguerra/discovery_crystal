require "redis"

p! redis = Redis.new
p! redis.set("foo", "bar", ex: 60)
p! redis.get("foo")

redis = Redis::PooledClient.new host: "localhost", port: 6379, database: 1, pool_timeout: 5.seconds, pool_size: 5
10.times do |i|
  puts "i: #{i}"
  spawn do
    puts "i fiber: #{i}"
    p! redis.set("foo#{i}", "bar", ex: 60)
    p! redis.get("foo#{i}") # => "bar"
  end
end

puts "Before yield"
Fiber.yield
puts "After yield"
