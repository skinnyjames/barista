require "spec"
require "http/server"
require "file_utils"

require "../src/barista"
require "./support/**"

include WithHelpers

def fixture_url
  "http://localhost:3003"
end

def fixtures_path
  Path["#{__DIR__}/support/fixtures"].expand.to_s
end

def downloads_path
  Path["#{__DIR__}/support/downloads"].expand.to_s
end

def reset_paths
  Dir.cd(downloads_path) do
    FileUtils.rm_r(Dir.children("."))
  end
end

Barista::Log.level = Log::Severity::Debug

server = HTTP::Server.new(HTTP::StaticFileHandler.new("#{fixtures_path}/files"))

Spec.before_each do
  reset_paths
end

Spec.after_each do
  reset_paths
end

Spec.after_suite do
  server.try(&.close)
end

spawn do
  server.listen(3003)
end