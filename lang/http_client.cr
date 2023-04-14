require "http/client"
require "uri"

params = URI::Params.encode({"author" => "John Doe", "offset" => "20"})
url = "http://mockbin.com?#{params}"
p! url

uri = URI.parse(url)
HTTP::Client.new(uri) do |client|
  p! client.tls? # => #<OpenSSL::SSL::Context::Client>
  client.connect_timeout = 5.seconds
  client.dns_timeout = 5.seconds
  client.read_timeout = 1.minutes
  client.write_timeout = 1.minutes

  res = client.get("/request")
  p! res.status_code
  p! res.body
end

def normalize_headers(headers : HTTP::Headers)
  headers.map do |header|
    key, value = header

    if value.is_a?(Array) && value.size == 1
      value = value.first
    end
    {key, value}
  end.to_h
end

def filename(raw_headers : HTTP::Headers, default_name : String) : String
  headers = normalize_headers(raw_headers)
  filename_regex = /filename\*?=['"]?(?:UTF-\d['"]*)?([^;\r\n"']*)['"]?;?/xi

  if match_data = headers.fetch("Content-Disposition", "").as(String).match(filename_regex)
    return match_data[1]
  end

  return default_name
end


puts "\n\n\nDownload file..."

HTTP::Client.get("https://codeload.github.com/crystal-lang/crystal/zip/refs/heads/master") do |response|
  name = filename(response.headers, "crystal.zip")
  p! response.status_code # => 200
  p! name

  File.open(name, "w") do |file|
    IO.copy(response.body_io, file)
  end
end
