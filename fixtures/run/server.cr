require "http/server"

server = HTTP::Server.new do |context|
  context.response.content_type = "text/plain"
  context.response.print "Hello world!"
end

address = server.bind_tcp (ENV["BREW_PORT"]?.try(&.to_i32) || raise "Missing BREW_PORT")
puts "Listening on http://#{address}"
server.listen
