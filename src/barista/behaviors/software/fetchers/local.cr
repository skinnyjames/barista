module Barista
  module Behaviors
    module Software
      module Fetchers
        class Local
          include FileUtils
        
          getter :source, :exclude

          def initialize(@source : String, *, @exclude = [] of String); end

          def execute(dest_dir : String, name : String)
            Merger.new(source, File.join(dest_dir, name), exclude: excluded).execute
          end

          def location
            source
          end

          private def excluded
            exclude.map do |excludes|
              File.join(source, excludes)
            end
          end
        end
      end
    end
  end
end
