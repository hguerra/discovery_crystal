APP_ENV  = ENV["APP_ENV"]? || "development"
APP_PORT = ENV["APP_PORT"]? ? ENV["APP_PORT"].to_i : 8080

def is_development
  APP_ENV == "development"
end
