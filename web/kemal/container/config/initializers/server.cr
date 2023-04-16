require "./kemal"
require "./handlers/auth"
require "kemal-csrf"

Kemal.config.env = APP_ENV
Kemal.config.port = APP_PORT
Kemal.config.app_name = "Tasks"
Kemal.config.powered_by_header = false

if is_development
  serve_static({"gzip" => false, "dir_listing" => false})
else
  serve_static false
  Kemal.config.logging = false
end

add_handler Handlers::ApplicationJsonHandler.new
add_handler Handlers::JwtHandler.new
add_context_storage_type(Auth::User)

# Enable redis
# add_handler CSRF.new

macro render_template(filename)
  render "src/tasks_web/views/#{ {{filename}} }.ecr", "src/tasks_web/views/layouts/application.ecr"
end

macro render_html(filename)
  render "src/tasks_web/views/#{ {{filename}} }.ecr"
end

macro render_partial(filename)
  render "src/tasks_web/views/#{ {{filename}} }.ecr"
end
