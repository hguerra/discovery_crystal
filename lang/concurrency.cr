i = 0
while i < 10
  spawn puts(i)
  i += 1
end

Fiber.yield

10.times do |i|
  spawn do
    puts i
  end
end

Fiber.yield

# channel = Channel(Nil).new

# spawn do
#   puts "Before send"
#   channel.send(nil)
#   puts "After send"
# end

# puts "Before receive"
# channel.receive
# puts "After receive"

channel = Channel(Int32).new

spawn do
  puts "Before first send"
  channel.send(1)
  puts "Before second send"
  channel.send(2)
end

puts "Before first receive"
value = channel.receive
puts value # => 1

puts "Before second receive"
value = channel.receive
puts value # => 2
