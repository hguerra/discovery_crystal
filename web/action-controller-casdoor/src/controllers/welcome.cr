# description of the welcome klass
class App::Welcome < App::Application
  base "/"

  # A welcome message
  @[AC::Route::GET("/")]
  def index : String
    welcome_text = "You're being trampled by Spider-Gazelle!"
    Log.warn { "logs can be collated using the request ID" }

    # You can use signals to change log levels at runtime
    # USR1 is debugging, USR2 is info
    # `kill -s USR1 %APP_PID`
    Log.debug { "use signals to change log levels at runtime" }

    welcome_text
  end

  # For API applications the return value of the function is expected to work with
  # all of the responder blocks (see application.cr)
  # the various responses are returned based on the Accepts header
  @[AC::Route::GET("/api/:example")]
  @[AC::Route::POST("/api/:example")]
  @[AC::Route::GET("/api/other/route")]
  def api(example : Int32) : NamedTuple(result: Int32)
    {
      result: example,
    }
  end

  # this file is built as part of the docker build
  OPENAPI = YAML.parse(File.exists?("openapi.yml") ? File.read("openapi.yml") : "{}")

  # returns the OpenAPI representation of this service
  @[AC::Route::GET("/openapi")]
  def openapi : YAML::Any
    OPENAPI
  end

  # Fake router for testing login
  @[AC::Route::GET("/fake/login")]
  def fake_login
    render template: "index.ecr"
  end

  # Fake router for testing login
  @[AC::Route::GET("/fake/login-with-user")]
  def fake_login_with_user
    session["user_id"] = "123"
    session["user_name"] = "John Doe"
    session["user_email"] = "john.doe@example.com"
    session["access_token"] = "1234567890"

    redirect_to "/fake/login"
  end

  # Fake router for testing dashboard
  @[AC::Route::GET("/fake/dashboard")]
  def fake_dashboard
    render template: "dashboard.ecr"
  end

  # Fake router for testing profile
  @[AC::Route::GET("/fake/profile")]
  def fake_profile
    render template: "profile.ecr"
  end

  # Fake router for testing logout
  @[AC::Route::GET("/fake/logout")]
  def fake_logout
    session.delete("user_id")
    session.delete("user_name")
    session.delete("user_email")
    session.delete("access_token")

    redirect_to "/fake/login"
  end
end
