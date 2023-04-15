require "backtracer"

def foo
  raise "bang!"
end

def bar
  foo
end

def baz
  bar
end

begin
  baz
rescue ex
  backtrace = Backtracer.parse(ex.backtrace)

  # Prints
  #
  # `foo` at foo.cr:4:3
  # `bar` at foo.cr:8:3
  # `baz` at foo.cr:12:3
  # ...
  backtrace.frames.each do |frame|
    puts frame
  end
end
