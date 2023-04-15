require "debug"

# DEBUG=1 crystal main.cr
time = Time.unix_ms(1681579493965)
p! time

debug!(time)

message = "hello"
debug!(message)
