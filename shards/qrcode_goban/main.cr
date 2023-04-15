require "goban"
require "goban/exporters/svg"

qr = Goban::QR.encode_string("https://github.com/hguerra", Goban::ECC::Level::Medium)
qr.print_to_console

puts "Get SVG string"
puts Goban::SVGExporter.svg_string(qr, 4)

puts "or export as a file"
Goban::SVGExporter.export(qr, "output.svg")
