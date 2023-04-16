require "../kemal"

module Handlers
  class ApplicationJsonHandler < Kemal::Handler
    {% for method in %w(GET POST PUT HEAD DELETE PATCH OPTIONS) %}
      only ["/api/*"], {{method}}
    {% end %}

    def call(env)
      return call_next env unless only_match? env
      env.response.content_type = "application/json"
      call_next env
    end
  end
end
