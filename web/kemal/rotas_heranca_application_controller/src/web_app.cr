require "./web_app/**"

# TODO: Write documentation for `WebApp`
module WebApp
  VERSION = "0.1.0"

  puts "> Starting server..."
  Kemal.run
end
