require "crest"
require "uri"
require "digest"

module Barista
  module Behaviors
    module Software
      module Fetchers
        class MissingPath < Exception; end
        class ChecksumMismatch < Exception; end
        class RetryExceeded < Exception; end
        
        # Helper module for verifying a checksum against a downloaded file.
        module Verifiable
          protected def verify_checksum(expected : String, algorithim : String, file_path : String)
            actual = OpenSSL::Digest.new(algorithim).file(file_path).final.hexstring

            if expected != actual
              raise ChecksumMismatch.new("Checksum mismatch on #{file_path}")
            end
          end

          protected def verify_checksum(to : String)
            tuple = algorithim
            return unless tuple

            mod, checksum = tuple
            return unless checksum

            verify_checksum(checksum, mod, to)
          end
        end

        # Base Net fetcher
        # Assumes that all sources are tar types
        # TODO: Revisit/Rewrite
        class Net
          include GenericCommands
          include Verifiable
          COMPRESSED_TAR_EXTENSIONS = %w{.tar.gz .tgz tar.bz2 .tar.xz .txz .tar.lzma}

          getter :uri, :algorithim, :headers, :tls, :binary, :compress, :strip, :extension

          @algorithim : Tuple(String, String?)? = nil

          def initialize(
            url : String,
            *,
            md5 : String? = nil,
            sha1 : String? = nil,
            sha256 : String? = nil,
            sha512 : String? = nil,
            @headers : HTTP::Headers = HTTP::Headers.new,
            @tls : HTTP::Client::TLSContext? = nil,
            @retry : Int32 = 2,
            @binary : Bool = false,
            @compress : Bool = false,
            @strip : Int32 = 1,
            @extension : String? = nil
          )
            @algorithim = [{ "MD5", md5 }, { "SHA1", sha1 }, { "SHA256", sha256 }, { "SHA512", sha512 }].reduce(nil) do |memo, val|
              val[1].nil? ? memo : val
            end

            @uri = URI.parse(url)
          end

          # downloads and extracts this url to `#{dest_dir}/#{name}`
          # which should also be
          # `#{project.source_dir}/#{task.name}`
          def execute(dest_dir : String, name : String)
            mode = binary ? "wb" : "w"

            headers.add("Accept-Encoding", "identity") unless compress

            with_retry do
              Crest.get(uri.to_s, headers: headers) do |response|
                File.write(download_path(dest_dir), response.body_io)
              end
            end

            verify_checksum(download_path(dest_dir)) if algorithim

            is_tar = COMPRESSED_TAR_EXTENSIONS.any? do |ext|
              download_path(dest_dir).ends_with?(ext)
            end

            extract(dest_dir, name) if is_tar
          end

          private def download_path(dest_dir)
            file_path = !uri.path.empty? ? "#{dest_dir}/#{uri.path.split("/")[-1]}" : "#{dest_dir}/#{uri.host}"
            
            if ext = extension
              return "#{file_path}#{ext}" if !file_path.ends_with?(ext)
            end

            file_path
          end

          private def with_retry(current : Int32 = 0, &block : ->)
            begin
              block.call
            rescue ex
              raise RetryExceeded.new("Failed to download #{uri} after #{@retry} retries: #{ex}") if current >= @retry
              with_retry(current.succ, &block)
            end
          end

          private def extract(dest_dir, name)
            downloaded_file = download_path(dest_dir)
          
            task_mkdir("#{dest_dir}/#{name}", parents: true)

            compression_switch = ""
            compression_switch = "-z"        if downloaded_file.ends_with?("gz")
            compression_switch = "--lzma -"  if downloaded_file.ends_with?("lzma")
            compression_switch = "-j"        if downloaded_file.ends_with?("bz2")
            compression_switch = "-J"        if downloaded_file.ends_with?("xz")

            Process.run(
              "tar -xvf #{downloaded_file} -C#{name} --strip-components=#{strip}",
              chdir: dest_dir,
              shell: true,
              output: Process::Redirect::Close,
              error: Process::Redirect::Close
            )
          end
        end
      end
    end
  end
end

