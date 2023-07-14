require "http/client"

raise "BREW_PORT not set" if ENV["BREW_PORT"]?.nil?

puts "Fetching"
puts HTTP::Client.get("http://localhost:#{ENV["BREW_PORT"]}").body

spawn do
  sleep 20
end

Fiber.yield
