require "spec"
require "http/server"
require "file_utils"
require "webmock"

require "../src/barista"
require "./support/**"

include WithHelpers

WebMock.allow_net_connect = true

def cache_callbacks
  callbacks = Barista::Behaviors::Omnibus::CacheCallbacks.new
  callbacks.fetch do |cacher|
    Support::Cacher.fetch_cache(cacher)
  end

  callbacks.update do |info, s|
    Support::Cacher.update_cache(info, s)
  end

  callbacks
end

def fixture_url
  "http://localhost:3003"
end

def fixtures_path
  Path["#{__DIR__}/support/fixtures"].expand.to_s
end

def downloads_path
  Path["#{__DIR__}/support/downloads"].expand.to_s
end

def cache_path
  File.join(fixtures_path, "files", "cache")
end

def external_fixture(script)
  "#{__DIR__}/../fixtures/#{script}"
end

def barista_test_user
  ENV["BARISTA_TEST_USER"]?
end

def with_webmock
  WebMock.allow_net_connect = false
  yield
ensure
  WebMock.reset
  WebMock.allow_net_connect = true
end

def reset_paths
  FileUtils.mkdir_p(cache_path)
  FileUtils.mkdir_p(downloads_path)

  Dir.cd(downloads_path) do
    FileUtils.rm_rf(Dir.children("."))
  end
  
  Dir.cd(cache_path) do
    FileUtils.rm_rf(Dir.children("."))
  end
end

def mkdir(path : String, parents : Bool = true)
  parents ? FileUtils.mkdir_p(path) : FileUtils.mkdir(path)
end

Barista::Log.level = Log::Severity::Debug

server = HTTP::Server.new([
  Support::CacheHandler.new(fixtures_path),  
  HTTP::StaticFileHandler.new("#{fixtures_path}/files")
])

Spec.before_each do
  reset_paths unless ENV["CLEAN"]? == "false"
end

Spec.after_each do
  reset_paths unless ENV["CLEAN"]? == "false"
end

Spec.after_suite do
  server.try(&.close)
end

spawn do
  server.listen(3003)
end