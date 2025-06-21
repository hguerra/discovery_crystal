require "uuid"
require "yaml"

abstract class App::Application < ActionController::Base
  # Configure your log source name
  # NOTE:: this is chaining from Log
  Log = ::App::Log.for("controller")

  template_path "./src/views/"
  layout "layout_main.ecr"

  # framework uses "application/json" by default
  add_responder("application/yaml") { |io, result| result.to_yaml(io) }
  add_responder("text/html") { |io, result| result.to_s(io) }

  # This makes it simple to match client requests with server side logs.
  # When building microservices this ID should be propagated to upstream services.
  @[AC::Route::Filter(:before_action)]
  def set_request_id
    request_id = UUID.random.to_s
    Log.context.set(
      client_ip: client_ip,
      request_id: request_id
    )
    response.headers["X-Request-ID"] = request_id

    # If this is an upstream service, the ID should be extracted from a request header.
    # request_id = request.headers["X-Request-ID"]? || UUID.random.to_s
    # Log.context.set client_ip: client_ip, request_id: request_id
    # response.headers["X-Request-ID"] = request_id
  end

  @[AC::Route::Filter(:before_action)]
  def set_date_header
    response.headers["Date"] = HTTP.format_time(Time.utc)
  end

  # covers no acceptable response format and not an acceptable post format
  @[AC::Route::Exception(AC::Route::NotAcceptable, status_code: HTTP::Status::NOT_ACCEPTABLE)]
  @[AC::Route::Exception(AC::Route::UnsupportedMediaType, status_code: HTTP::Status::UNSUPPORTED_MEDIA_TYPE)]
  def bad_media_type(error) : AC::Error::ContentResponse
    AC::Error::ContentResponse.new error: error.message.as(String), accepts: error.accepts
  end

  # handles paramater missing or a bad paramater value / format
  @[AC::Route::Exception(AC::Route::Param::MissingError, status_code: HTTP::Status::UNPROCESSABLE_ENTITY)]
  @[AC::Route::Exception(AC::Route::Param::ValueError, status_code: HTTP::Status::BAD_REQUEST)]
  def invalid_param(error) : AC::Error::ParameterResponse
    AC::Error::ParameterResponse.new error: error.message.as(String), parameter: error.parameter, restriction: error.restriction
  end

  # Métodos de autenticação
  struct User
    include JSON::Serializable

    getter id : String
    getter name : String
    getter email : String
    getter access_token : String
    getter roles : Array(String)

    def initialize(@id : String, @name : String, @email : String, @access_token : String, @roles : Array(String) = [] of String)
      @id = id
      @name = name
      @email = email
      @access_token = access_token
      @roles = roles
    end
  end

  def current_user : User?
    return nil unless session["user_id"]?

    roles = session["user_roles"]?.try(&.as(String).split(",").reject(&.empty?)) || [] of String

    User.new(
      id: session["user_id"].as(String),
      name: session["user_name"]?.try(&.as(String)) || "",
      email: session["user_email"]?.try(&.as(String)) || "",
      access_token: session["access_token"]?.try(&.as(String)) || "",
      roles: roles
    )
  end

  def require_auth
    unless current_user
      redirect_to "/login"
      return
    end
  end

  def logged_in?
    current_user != nil
  end
end
