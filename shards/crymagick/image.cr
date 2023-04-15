require "crymagick"

CryMagick::Tool::Convert.build do |convert|
  convert << "exemplo.jpg"
  convert.colorspace("gray")
  convert << "output.jpg"
end
