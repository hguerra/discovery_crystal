require "tesseract-ocr"

# https://ai-facets.org/tesseract-ocr-best-practices/
text = Tesseract::Ocr.read("page.jpg", {  :l => "eng", :oem => "1" })
puts text
