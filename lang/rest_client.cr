require "http/client"

module MyApp
  struct RequestConfiguration
    getter headers : Hash(String, String) | Nil
    getter params : Hash(String, String) | Nil

    def initialize(@headers : Hash(String, String))
    end

    def initialize(@params : Hash(String, String))
    end

    def initialize(@headers : Hash(String, String), @params : Hash(String, String))
    end
  end

  class RestClient
    @http_client : HTTP::Client

    def initialize(@host : String)
      uri = URI.parse(@host)
      @http_client = HTTP::Client.new(uri).tap do |c|
        c.connect_timeout = 5.seconds
        c.dns_timeout = 5.seconds
        c.read_timeout = 1.minutes
        c.write_timeout = 1.minutes
      end
    end

    def get(path : String, config : RequestConfiguration | Nil = nil)
      headers = http_headers
      params = http_params

      if config
        if config.headers
          config.headers.each do |key, value|
            headers.add(key, value)
          end
        end

        if config.params
          config.params.each do |key, value|
            params.add(key, value)
          end
        end
      end

      unless params.empty?
        path = "#{path}?#{params}"
      end

      @http_client.get(path, headers: headers)
    end

    private def http_headers
      HTTP::Headers{
        "accept" => "application/json",
        "content-type" => "application/json",
      }
    end

    private def http_params
      HTTP::Params.new
    end
  end
end

client = MyApp::RestClient.new "http://mockbin.org"
res = client.get("/request")
p! res.status_code
p! res.body
