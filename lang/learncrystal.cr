# This is a comment
# https://learnxinyminutes.com/docs/crystal/

# Everything is an object
p! nil.class  #=> Nil
p! 100.class  #=> Int32
p! true.class #=> Bool

# Falsey values are: nil, false and null pointers
p! !nil   #=> true  : Bool
p! !false #=> true  : Bool
p! !0     #=> false : Bool


1.class #=> Int32

# Five signed integer types
p! 1_i8.class   #=> Int8
p! 1_i16.class  #=> Int16
p! 1_i32.class  #=> Int32
p! 1_i64.class  #=> Int64
p! 1_i128.class #=> Int128

# Five unsigned integer types
p! 1_u8.class   #=> UInt8
p! 1_u16.class  #=> UInt16
p! 1_u32.class  #=> UInt32
p! 1_u64.class  #=> UInt64
p! 1_u128.class #=> UInt128
p! 9223372036854775808.class #=> UInt64

# Binary numbers
p! 0b1101 #=> 13 : Int32

# Octal numbers
p! 0o123 #=> 83 : Int32

# Hexadecimal numbers
p! 0xFE012D #=> 16646445 : Int32
p! 0xfe012d #=> 16646445 : Int32

# Floats

p! 1.0.class #=> Float64

# There are two floating point types
p! 1.0_f32.class #=> Float32
p! 1_f32.class   #=> Float32

p! 1e10.class    #=> Float64
p! 1.5e10.class  #=> Float64
p! 1.5e-7.class  #=> Float64

# Chars use 'a' pair of single quotes

p! 'a'.class #=> Char

# Chars are 32-bit unicode
p! 'あ' #=> 'あ' : Char

# Unicode codepoint
p! '\u0041' #=> 'A' : Char


# Strings use a "pair" of double quotes

p! "s".class #=> String

# Strings are immutable
p! s = "hello, "  #=> "hello, "        : String
p! s.object_id    #=> 134667712        : UInt64
p! s += "Crystal"
p! s              #=> "hello, Crystal" : String
p! s.object_id    #=> 142528472        : UInt64

# Supports interpolation
p! "sum = #{1 + 2}" #=> "sum = 3" : String

# Multiline string
p! "This is
   multiline string" #=> "This is\n   multiline string"


# String with double quotes
p! %(hello "world") #=> "hello \"world\""



# Symbols
# Immutable, reusable constants represented internally as Int32 integer value.
# They're often used instead of strings to efficiently convey specific,
# meaningful values

p! :symbol.class #=> Symbol

p! sentence = :question?     # :"question?" : Symbol

p! sentence == :question?    #=> true  : Bool
p! sentence == :exclamation! #=> false : Bool
p! sentence == "question?"   #=> false : Bool


# Arrays

p! [1, 2, 3].class         #=> Array(Int32)
p! [1, "hello", 'x'].class #=> Array(Char | Int32 | String)

# Empty arrays should specify a type
# []               # Syntax error: for empty arrays use '[] of ElementType'
p! [] of Int32      #=> [] : Array(Int32)
p! Array(Int32).new #=> [] : Array(Int32)


# Arrays can be indexed
p! array = [1, 2, 3, 4, 5] #=> [1, 2, 3, 4, 5] : Array(Int32)
p! array[0]                #=> 1               : Int32
# p! array[10]               # raises IndexError
# p! array[-6]               # raises IndexError
p! array[10]?              #=> nil             : (Int32 | Nil)
p! array[-6]?              #=> nil             : (Int32 | Nil)

# From the end
p! array[-1] #=> 5

# With a start index and size
p! array[2, 3] #=> [3, 4, 5]

# Or with range
p! array[1..3] #=> [2, 3, 4]

# Add to an array
p! array << 6  #=> [1, 2, 3, 4, 5, 6]

# Remove from the end of the array
p! array.pop #=> 6
p! array     #=> [1, 2, 3, 4, 5]

# Remove from the beginning of the array
p! array.shift #=> 1
p! array       #=> [2, 3, 4, 5]

# Check if an item exists in an array
p! array.includes? 3 #=> true

# Special syntax for an array of string and an array of symbols
p! %w(one two three) #=> ["one", "two", "three"] : Array(String)
p! %i(one two three) #=> [:one, :two, :three]    : Array(Symbol)



# There is a special array syntax with other types too, as long as
# they define a .new and a #<< method
p! set = Set{1, 2, 3} #=> Set{1, 2, 3}
p! set.class          #=> Set(Int32)

# The above is equivalent to
p! set = Set(typeof(1, 2, 3)).new #=> Set{} : Set(Int32)
p! set = Set(Int32).new #=> Set{} : Set(Int32)
p! set << 1                       #=> Set{1} : Set(Int32)
p! set << 2                       #=> Set{1, 2} : Set(Int32)
p! set << 3                       #=> Set{1, 2, 3} : Set(Int32)


# Hashes

h1 = {1 => 2, 3 => 4}.class   #=> Hash(Int32, Int32)
h2 = {1 => 2, 'a' => 3}.class #=> Hash(Char| Int32, Int32)
p! h1
p! h2

# Empty hashes must specify a type
# {}                     # Syntax Error: for empty hashes use '{} of KeyType => ValueType'
{} of Int32 => Int32   # {} : Hash(Int32, Int32)
h1 = Hash(Int32, Int32).new # {} : Hash(Int32, Int32)
p! h1


# Hashes can be quickly looked up by key
hash = {"color" => "green", "number" => 5}
p! hash.class
p! hash["color"]        #=> "green"
# p! hash["no_such_key"]  #=> Missing hash key: "no_such_key" (KeyError)
p! hash["no_such_key"]? #=> nil


# The type of the returned value is based on all key types
p! hash["number"] #=> 5 : (Int32 | String)
p! hash["number"].class #=> 5 : (Int32 | String)

# Check existence of keys hash
p! hash.has_key? "color" #=> true

# Special notation for symbol and string keys
h1 = {key1: 'a', key2: 'b'}     # {:key1 => 'a', :key2 => 'b'}
h2 = {"key1": 'a', "key2": 'b'} # {"key1" => 'a', "key2" => 'b'}
p! h1
p! h2
p! h1[:key1]


# Special hash literal syntax with other types too, as long as
# they define a .new and a #[]= methods
class MyType
  def []=(key, value)
    puts "do stuff"
  end
end

MyType{"foo" => "bar"}

# The above is equivalent to
p! tmp = MyType.new
p! tmp["foo"] = "bar"
p! tmp


# Ranges

p! 1..10                  #=> Range(Int32, Int32)
p! Range.new(1, 10).class #=> Range(Int32, Int32)

# Can be inclusive or exclusive
p! (3..5).to_a  #=> [3, 4, 5]
p! (3...5).to_a #=> [3, 4]

# Check whether range includes the given value or not
p! (1..8).includes? 2 #=> true


# Tuples are a fixed-size, immutable, stack-allocated sequence of values of
# possibly different types.
# p! {1, "hello", 'x'}.class #=> Tuple(Int32, String, Char)

# Access tuple's value by its index
p! tuple = {:key1, :key2}
p! tuple[1] #=> :key2
# p! tuple[2] #=> Error: index out of bounds for Tuple(Symbol, Symbol) (2 not in -2..1)

# Can be expanded into multiple variables
a, b, c = {:a, 'b', "c"}
p! a #=> :a
p! b #=> 'b'
p! c #=> "c"


# Procs represent a function pointer with an optional context (the closure data)
# It is typically created with a proc literal
proc = ->(x : Int32) { x.to_s }
p! proc.class # Proc(Int32, String)
# Or using the new method
p! Proc(Int32, String).new { |x| x.to_s }

# Invoke proc with call method
p! proc.call 10 #=> "10"


# Control statements

if true
  "if statement"
elsif false
  "else-if, optional"
else
  "else, also optional"
end

puts "if as a suffix" if true

# If as an expression
a = if 2 > 1
  3
else
  4
end

p! a #=> 3


# Ternary if
a = 1 > 2 ? 3 : 4 #=> 4



# Case statement
cmd = "move"

action = case cmd
  when "create"
    "Creating..."
  when "copy"
    "Copying..."
  when "move"
    "Moving..."
  when "delete"
    "Deleting..."
end

p! action #=> "Moving..."



# Loops
index = 0
while index <= 3
  puts "Index: #{index}"
  index += 1
end
# Index: 0
# Index: 1
# Index: 2
# Index: 3

index = 0
until index > 3
  puts "Index: #{index}"
  index += 1
end
# Index: 0
# Index: 1
# Index: 2
# Index: 3

# But the preferable way is to use each
(1..3).each do |index|
  puts "Index: #{index}"
end
# Index: 1
# Index: 2
# Index: 3



# Variable's type depends on the type of the expression
# in control statements
if a < 3
  a = "hello"
else
  a = true
end
p! typeof(a) #=> (Bool | String)

if a.is_a? String
  p ! a.class #=> String
end




# Functions

def double(x)
  x * 2
end

# Functions (and all blocks) implicitly return the value of the last statement
p! double(2) #=> 4

# Parentheses are optional where the call is unambiguous
p! double 3 #=> 6

p! double double 3 #=> 12

def sum(x, y)
  x + y
end


# Method arguments are separated by a comma
p! sum 3, 4 #=> 7

p! sum sum(3, 4), 5 #=> 12

# yield
# All methods have an implicit, optional block parameter
# it can be called with the 'yield' keyword

def surround
  puts '{'
  yield "a"
  puts '}'
end

p! surround { |x| puts "hello world #{x}" }

# You can pass a block to a function
# "&" marks a reference to a passed block
def twice(&block)
  block.call
  yield
end

twice do
  puts "Hello!"
end

twice { puts "Hello!" }

# You can pass a block to a function
# "&" marks a reference to a passed block
def guests(&block)
  yield "some_argument"
end

# guests # Error wrong number of block parameters
guests { |x| puts x }

# You can pass a list of arguments, which will be converted into an array
# That's what splat operator ("*") is for
def guests(*array)
  p! array
  array.each { |guest| puts guest }
end

guests 1, 2, 3


# If a method returns an array, you can use destructuring assignment
def foods
  ["pancake", "sandwich", "quesadilla"]
end
breakfast, lunch, dinner = foods
p! breakfast #=> "pancake"
p! dinner    #=> "quesadilla"


# By convention, all methods that return booleans end with a question mark
p! 5.even? # false
p! 5.odd?  # true


# Also by convention, if a method ends with an exclamation mark, it does
# something destructive like mutate the receiver.
# Some methods have a ! version to make a change, and
# a non-! version to just return a new changed version
fruits = ["grapes", "apples", "bananas"]
p! fruits.sort  #=> ["apples", "bananas", "grapes"]
p! fruits       #=> ["grapes", "apples", "bananas"]
p! fruits.sort! #=> ["apples", "bananas", "grapes"]
p! fruits       #=> ["apples", "bananas", "grapes"]


# However, some mutating methods do not end in !
fruits.shift #=> "apples"
p! fruits       #=> ["bananas", "grapes"]



# Define a class with the class keyword
class Human

  # A class variable. It is shared by all instances of this class.
  @@species = "H. sapiens"
  @@foo = 0

  # An instance variable. Type of name is String
  @name : String

  # Basic initializer
  # Assign the argument to the "name" instance variable for the instance
  # If no age given, we will fall back to the default in the arguments list.
  def initialize(@name, @age = 0)
  end

  # Basic setter method
  def name=(name)
    @name = name
  end

  # Basic getter method
  def name
    @name
  end

  # The above functionality can be encapsulated using the propery method as follows
  property :name

  # Getter/setter methods can also be created individually like this
  getter :name
  setter :name

  # A class method uses self to distinguish from instance methods.
  # It can only be called on the class, not an instance.
  def self.say(msg)
    puts msg
  end

  def self.foo
    @@foo
  end

  def self.foo=(value)
    @@foo = value
  end

  def species
    @@species
  end
end


# Instantiate a class
jim = Human.new("Jim Halpert")

dwight = Human.new("Dwight K. Schrute")

# Let's call a couple of methods
p! jim.species #=> "H. sapiens"
p! jim.name #=> "Jim Halpert"
p! jim.name = "Jim Halpert II" #=> "Jim Halpert II"
p! jim.name #=> "Jim Halpert II"
p! dwight.species #=> "H. sapiens"
p! dwight.name #=> "Dwight K. Schrute"

# Call the class method
p! Human.say("Hi") #=> print Hi and returns nil


# Variables that start with @ have instance scope
class TestClass
  @var = "I'm an instance var"
end

# Variables that start with @@ have class scope
class TestClass
  @@var = "I'm a class var"
end

# Variables that start with a capital letter are constants
Var = "I'm a constant"
# Var = "can't be updated" # Error: already initialized constant Var

# derived class
class Worker < Human
end

p! Worker.say "Hi"

p! Human.foo   #=> 0
p! Worker.foo  #=> 0

p! Human.foo = 2 #=> 2
p! Worker.foo    #=> 0

p! Worker.foo = 3 #=> 3
p! Human.foo   #=> 2
p! Worker.foo  #=> 3

module ModuleExample
  def foo
    "foo"
  end
end

# Including modules binds their methods to the class instances
# Extending modules binds their methods to the class itself

class Person
  include ModuleExample
end

class Book
  extend ModuleExample
end

# Person.foo     # => undefined method 'foo' for Person:Class
p! Person.new.foo # => 'foo'
p! Book.foo       # => 'foo'
# Book.new.foo   # => undefined method 'foo' for Book


# Exception handling

# Define new exception
class MyException < Exception
end

# Define another exception
class MyAnotherException < Exception; end

ex = begin
   raise MyException.new
rescue ex1 : IndexError
  "ex1"
rescue ex2 : MyException | MyAnotherException
  "ex2"
rescue ex3 : Exception
  "ex3"
rescue ex4 # catch any kind of exception
  "ex4"
end

p! ex #=> "ex2"
