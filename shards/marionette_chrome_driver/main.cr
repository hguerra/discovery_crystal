require "marionette"

exe_path = "./bin/chromedriver"
port = 9515
session = Marionette::WebDriver.create_session(:chrome, exe_path, port)

session.navigate("https://translate.google.com/?hl=pt-BR&sl=en&tl=pt&op=translate")

text_area = session.find_element!("textarea")
text_area.send_keys "crystal programming language", Marionette::Key::Enter
sleep 5

session.wait_for_element("span[lang=\"pt\"]") do |element|
  p! element.text
  sleep 5.seconds
end

session.stop

sleep 5
session.close
