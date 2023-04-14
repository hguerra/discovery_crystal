require "kemal"

module WebKamal
  extend self
  VERSION = "0.1.0"

  # https://github.com/hugopl/sidekiq.cr/blob/master/src/sidekiq/web.cr#L39
  macro ecr(xxx)
    {% if xxx.starts_with?('_') %}
      render "src/views/#{{{xxx}}}.ecr"
    {% else %}
      render "src/views/#{{{xxx}}}.ecr", "src/views/layouts/layout.ecr"
    {% end %}
  end

  before_all "/foo" do |env|
    puts "Setting response content type"
    env.response.content_type = "application/json"
  end

  get "/" do
    {"name": "Home"}.to_json
  end

  get "/:name" do |env|
    name = env.params.url["name"]
    render "src/views/hello.ecr"
  end

  get "/subview/:name" do |env|
    name = env.params.url["name"]
    ecr "subview"
  end

  get "/foo" do |env|
    puts env.response.headers["Content-Type"] # => "application/json"
    {"name": "Kemal"}.to_json
  end

  put "/foo" do |env|
    puts env.response.headers["Content-Type"] # => "application/json"
    {"name": "Kemal"}.to_json
  end

  post "/foo" do |env|
    puts env.response.headers["Content-Type"] # => "application/json"
    {"name": "Kemal"}.to_json
  end

  def call
    serve_static({"gzip" => false, "dir_listing" => false})

    Kemal.run
  end
end

WebKamal.call
