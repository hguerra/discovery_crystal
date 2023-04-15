require "pluto"
require "pluto/format/jpeg"

image = File.open("./exemplo.jpg") do |file|
  Pluto::ImageRGBA.from_jpeg(file)
end

new_image = image.to_ga

io = IO::Memory.new
new_image.to_jpeg(io)
io.rewind
File.write("output.jpeg", io)

