require "file_utils"

module Barista
  module Behaviors
    module Software
      # Copies files from `source` to `destination`
      # Merger.new("/opt/barista/cache/task/build", "/opt/barista/embedded").execute
      #
      # Can provide a block that takes a `source` and `target` params to stop a file copy
      #
      # return `true` from the block to continue with the copy
      #
      # return `false` to skip this file copy
      struct Merger
        getter :source, :destination, :strategy, :exclude, :always_check

        alias Strategy = Proc(String, String, Bool)

        def initialize(@source : String, @destination : String, @exclude = [] of String, @always_check : Bool = false, &block : Merger::Strategy);
          @strategy = block
        end

        def initialize(@source : String, @destination : String, @exclude = [] of String)
          @always_check = false
          @strategy = nil
        end

        # run the merge.  If `keep_links` is true, the symbolic links will
        # be copied as-is.
        def execute(keep_links : Bool = false)
          source_dir = Path[source].normalize
          files = Dir["#{source_dir}/**/*", match_hidden: true] - exclusions - ["..", "."]

          files.each do |file_path|
            next if File.directory?(file_path)

            relative = relative_path_for(file_path, source)
            parent = File.join(destination, File.dirname(relative)).gsub(/\.$/, "")
            target = "#{destination}/#{relative}"


            # allow skipping of sync with block
            proc = strategy
            if proc && (always_check || File.exists?(target))
              do_write = proc.call(file_path, target)
              next unless do_write
            end

            # make the parent directory if it doesn't exist
            FileUtils.mkdir_p(parent) unless Dir.exists?(parent)

            info = File.info(file_path, false)

            case info.type
            when .file?
              File.copy(file_path, target)
            when .symlink?
              real_path = File.readlink(file_path)
              relative_real = relative_path_for(real_path, source)

              if keep_links
                File.symlink(real_path, target)
                next
              end

              if Path[real_path].absolute?
                to_be_link = File.join(destination, relative_real)

                File.symlink(to_be_link, target)
              else
                File.symlink(relative_real, target)
              end
            end
          end
        end

        def relative_path_for(path, source)
          Path[path].relative_to(source).to_s
        end

        def exclusions
          Dir.glob(exclude, true)
        end
      end
    end
  end
end
