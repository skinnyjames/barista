require "http"

module Support
  class CacheHandler
    include HTTP::Handler

    getter :fixtures_path

    def initialize(@fixtures_path : String); end

    def call(context)
      req = context.request
      name = nil
      tempfile = nil
      if req.path == "/cache" && req.method == "POST"
        HTTP::FormData.parse(req) do |part|
          case part.name
          when "tag"
            name = part.body.gets_to_end
          when "file"
            tempfile = File.tempfile("upload") do |file|
              IO.copy(part.body, file)
            end
          end
        end

        unless name && tempfile
          context.response.respond_with_status(:bad_request)
          call_next(context)
        else
          FileUtils.mkdir_p("#{fixtures_path}/files/cache") unless Dir.exists?("#{fixtures_path}/files/cache")
          File.copy(tempfile.path, "#{fixtures_path}/files/cache/#{name}.tar.gz")
          context.response << "#{fixtures_path}/files/cache/#{name}.tar.gz"
        end
      else
        call_next(context)
      end
    end
  end
end
