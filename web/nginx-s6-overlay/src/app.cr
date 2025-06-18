require "http"

# TODO: Write documentation for `App`
module App
  VERSION = "0.1.0"

  server = HTTP::Server.new do |ctx|
    ctx.response.content_type = "text/plain"
    ctx.response.print "Hello from Crystal backend!"
  end

  address = server.bind_tcp("0.0.0.0", 3000)
  puts "🚀 Crystal server listening on #{address}"
  server.listen
end
