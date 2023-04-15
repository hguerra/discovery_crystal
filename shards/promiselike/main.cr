require "http/client"
require "promise"

def fetch_websites_async
  %w[
    www.github.com
    www.yahoo.com
    www.facebook.com
    www.twitter.com
    crystal-lang.org
  ].map do |url|
    Promise.defer do
      HTTP::Client.get "https://#{url}"
    end
  end
end

puts "Criando promises..."
promises = fetch_websites_async
# Promise.all(promises).then do |results|
#   results.each do |res|
#     puts "Res: #{res.status_code}"
#   end
# end

puts "Executando promises (.get para esperar)..."
results = Promise.all(promises).get
results.each do |res|
  puts "Res: #{res.status_code}"
end
