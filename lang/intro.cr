message = "Heitor"
p! typeof(message)
p! message

message = 73
p! typeof(message)
p! message

p! 1 == 1,
  1 == 2,
  1.0 == 1,
  -2000.0 == -2000

p! 2 > 1,
  1 >= 1,
  1 < 2,
  1 <= 2

p! 1 <=> 1,
  2 <=> 1,
  1 <=> 2

p! 1 + 1, # addition
  1 - 1,  # subtraction
  2 * 3,  # multiplication
  2 ** 4, # exponentiation
  2 / 3,  # division
  2 // 3, # floor division
  3 % 2,  # modulus
  -1      # negation (unary)

p! 4 + 5 * 2,
  (4 + 5) * 2

p! -5.abs,   # absolute value
  4.3.round, # round to nearest integer
  5.even?,   # odd/even check
  10.gcd(16) # greatest common divisor

p! Math.cos(1),     # cosine
  Math.sin(1),      # sine
  Math.tan(1),      # tangent
  Math.log(42),     # natural logarithm
  Math.log10(312),  # logarithm to base 10
  Math.log(312, 5), # logarithm to base 5
  Math.sqrt(9)      # square root

p! Math::E,  # Euler's number
  Math::TAU, # Full circle constant (2 * PI)
  Math::PI   # Archimedes' constant (TAU / 2)

puts "I say: \"Hello \\\n\tWorld!\""
puts %(I say: "Hello World!")

puts "Hello 🌐"
puts "Hello \u{1F310}"

message = "Hello World! Greetings from Crystal."

puts "normal: #{message}"
puts "upcased: #{message.upcase}"
puts "downcased: #{message.downcase}"
puts "camelcased: #{message.camelcase}"
puts "capitalized: #{message.capitalize}"
puts "reversed: #{message.reverse}"
puts "titleized: #{message.titleize}"
puts "underscored: #{message.underscore}"
p! message.size

empty_string = ""

p! empty_string.size == 0,
  empty_string.empty?

blank_string = "   "

p! blank_string.blank?,
  blank_string.presence

message = "Hello World!"

p! message == "Hello World",
  message == "Hello Crystal",
  message == "hello world",
  message.compare("hello world", case_insensitive: false),
  message.compare("hello world", case_insensitive: true)

message = "Hello World!"

p! message.includes?("Crystal"),
  message.includes?("World")

message = "Hello World!"

p! message.starts_with?("Hello"),
  message.starts_with?("Bye"),
  message.ends_with?("!"),
  message.ends_with?("?")

p! "Crystal is awesome".index("Crystal"),
  "Crystal is awesome".index("s"),
  "Crystal is awesome".index("aw")

message = "Crystal is awesome"

p! message.index("s"),
  message.index("s", offset: 4),
  message.index("s", offset: 10)

message = "Crystal is awesome"

p! message.rindex("s"),
  message.rindex("s", 13),
  message.rindex("s", 8)

a = "Crystal is awesome".index("aw")
p! a, typeof(a)
b = "Crystal is awesome".index("meh")
p! b, typeof(b)

message = "Hello World!"
p! message[6, 5]
p! message[6]

message = "Hello World!"
p! message[6, message.size - 6 - 1]

p! message[6..(message.size - 2)],
  message[6..-2]

p! message.sub(6..-2, "Crystal")
p! message.sub("World", "Crystal")

message = "Hello World! How are you, World?"
p! message.sub("World", "Crystal"),
  message.gsub("World", "Crystal")

a = true
b = false

p! a && b, # conjunction (AND)
  a || b,  # disjunction (OR)
  !a,      # negation (NOT)
  a != b,  # inequivalence (XOR)
  a == b   # equivalence

a = "foo"
b = nil

p! a && b, # conjunction (AND)
  a || b,  # disjunction (OR)
  !a,      # negation (NOT)
  a != b,  # inequivalence (XOR)
  a == b   # equivalence

p! "foo" && nil,
  "foo" && false,
  false || "foo",
  "bar" || "foo",
  nil || "foo"

message = "Hello World"

if message.starts_with?("Hello")
  puts "Hello to you, too!"
end

message = "Hello World"

# if not
unless message.starts_with?("Hello")
  puts "I didn't understand that."
end

str = "Crystal is awesome"
index = str.index("aw")
# unless index.nil?
if index
  puts str
  puts "#{" " * index}^^"
end

message = "Bye World"

if message.starts_with?("Hello")
  puts "Hello to you, too!"
elsif message.starts_with?("Bye")
  puts "See you later!"
else
  puts "I didn't understand that."
end

counter = 0

while counter < 10
  counter += 1

  puts "Counter: #{counter}"
end

counter = 0

until counter >= 10
  counter += 1

  puts "Counter: #{counter}"
end

counter = 0

while counter < 10
  counter += 1

  if counter % 3 == 0
    next
  end

  puts "Counter: #{counter}"
end

counter = 0

while true
  counter += 1

  puts "Counter: #{counter}"

  if counter >= 10
    break
  end
end

puts "done"

def say_hello(recipient = "World")
  puts "Hello #{recipient}!"
end

def say_hello2(recipient : String = "a")
  puts "Hello #{recipient}!"
end

def say_hello2(times : Int32)
  puts "Hello " * times
end

say_hello "World"
say_hello "Crystal"
say_hello nil
say_hello
say_hello 6
say_hello2 "b"
say_hello2 6

def adds_2(n : Int32)
  n + 2
end

puts adds_2 40

# This method returns:
# - the same number if it's even,
# - the number multiplied by 2 if it's odd.
def build_even_number(n : Int32) : Int32
  return n if n.even?

  n * 2
end

puts build_even_number 7
puts build_even_number 28

10.times.each do |n|
  puts n
end

[[1, "A"], [2, "B"]].each do |(a, b)|
  pp a
  pp b
end
