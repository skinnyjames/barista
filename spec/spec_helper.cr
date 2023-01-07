require "spec"
require "http/server"
require "file_utils"

require "../src/barista"
require "./support/**"

include WithHelpers

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

def reset_paths
  FileUtils.mkdir_p(cache_path)
  FileUtils.mkdir_p(downloads_path)

  Dir.cd(downloads_path) do
    FileUtils.rm_r(Dir.children("."))
  end
  
  Dir.cd(cache_path) do
    FileUtils.rm_r(Dir.children("."))
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