require "yaml"

APP_ENV = ENV["APP_ENV"]? || "development"

yaml = File.open("config/database.yml") do |file|
  uri = ENV["DATABASE_URI"] if ENV.has_key?("DATABASE_URI")
  log_level = APP_ENV == "development" ? :debug : :error

  config = YAML.parse(file)

  p! uri, log_level, config
end
