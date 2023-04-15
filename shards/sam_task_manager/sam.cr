require "./config/*"
require "sam"

task "name" do |t|
  t.invoke("surname")
end

task "surname" do
  puts "\n\n\nSnow"
  puts I18n.translate("message.new", {text: "hello"})
  puts I18n.translate("message.new", {:text => "hello"})
  puts I18n.translate("message.new", {"text" => "hello"})
  puts I18n.translate("message.new", {"text" => "hello"}, "en")
  puts I18n.localize(Time.local, scope: :date, format: :long)
end

# crystal sam.cr name
# crystal sam.cr generate:makefile
Sam.help
