module Barista
  module Behaviors
    module Software
      module Fetchers
        class Local
          include FileUtils
        
          getter :source

          def initialize(@source : String); end

          def execute(dest_dir : String, name : String)
            cp_r(source, File.join(dest_dir, name))
          end

          def location
            source
          end
        end
      end
    end
  end
end
