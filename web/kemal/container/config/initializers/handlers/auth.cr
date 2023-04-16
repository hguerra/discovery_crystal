require "log"
require "../kemal"

module Auth
  CONTEXT_USER          = "user"
  COOKIE                = "token"
  DEFAULT_TOKEN_EXP_MIN = 15.minutes

  LOGGER = Log.for(self)

  struct Claims
    include JSON::Serializable
    include JSON::Serializable::Unmapped

    @[JSON::Field(key: "sub")]
    @subject : String

    @[JSON::Field(key: "r")]
    @roles : Array(String)

    getter subject, roles
  end

  struct User
    include JSON::Serializable

    getter token, claims

    def initialize(@token : String, @claims : Claims)
    end
  end

  class LoginService
    def self.call(env, email : String)
      LOGGER.info { "Login of e-mail #{email}..." }
      env.response.cookies << HTTP::Cookie.new(
        name: COOKIE,
        value: "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJkb21haW4uY29tIiwiaWF0IjoxNjgyMDM5OTAzLCJleHAiOjE2ODIwNDExMDUsImF1ZCI6ImRvbWFpbi5jb20iLCJzdWIiOiJqcm9ja2V0QGV4YW1wbGUuY29tIiwibmFtZSI6IkpvaG5ueSIsImVtYWlsIjoianJvY2tldEBleGFtcGxlLmNvbSIsInIiOlsiTWFuYWdlciIsIlByb2plY3QgQWRtaW5pc3RyYXRvciJdfQ.Z68L1xh0VUgaruXeU3DS4Tm5G7g1-Rfev-3Rn6_YnXU",
        http_only: false,
        expires: Time.local.to_utc + DEFAULT_TOKEN_EXP_MIN
      )
    end
  end

  class RefreshCookieService
    def self.call(env, user : Auth::User)
      # Exp time shoul be from Token
      env.response.cookies << HTTP::Cookie.new(
        name: COOKIE,
        value: user.token,
        http_only: false,
        expires: Time.local.to_utc + DEFAULT_TOKEN_EXP_MIN
      )
    end
  end
end

module Handlers
  class JwtHandler < Kemal::Handler
    HEADER                = "Authorization"
    TYPE                  = "Bearer"
    AUTH_MESSAGE          = "Could not verify your access level for that URL.\nYou have to login with proper credentials"
    HEADER_LOGIN_REQUIRED = "#{TYPE} realm=\"Login Required\""

    {% for method in %w(GET POST PUT HEAD DELETE PATCH OPTIONS) %}
      exclude ["/", "/login", "/about"], {{method}}
    {% end %}

    def call(env)
      if env.request.cookies[Auth::COOKIE]?
        if value = env.request.cookies[Auth::COOKIE].value
          if user = authorize_cookie? value
            env.set Auth::CONTEXT_USER, user
            Auth::RefreshCookieService.call env, user
            return call_next env
          end
        end
      end

      if env.request.headers[HEADER]?
        if value = env.request.headers[HEADER]
          if user = authorize_bearer? value
            env.set Auth::CONTEXT_USER, user
            return call_next env
          end
        end
      end

      return call_next env if exclude_match? env

      env.response.status_code = HTTP::Status::FORBIDDEN.code
      env.response.headers["WWW-Authenticate"] = HEADER_LOGIN_REQUIRED
      env.response.print AUTH_MESSAGE
      env.redirect "/"
    end

    def authorize?(token : String) : Auth::User?
      return nil unless token.count(".") >= 2

      payload = Base64.decode_string(token.split(".")[1])
      claims = Auth::Claims.from_json(payload)
      Auth::User.new token, claims
    end

    def authorize_bearer?(value) : Auth::User?
      return nil unless value.size > 0 && value.starts_with? TYPE
      authorize? value[TYPE.size + 1..-1]
    end

    def authorize_cookie?(value) : Auth::User?
      return nil unless value.size > 0
      authorize? value
    end
  end
end
