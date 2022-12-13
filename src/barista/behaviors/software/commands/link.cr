module Barista
  module Behaviors
    module Software
      module Commands
        class Link < Base
          getter :source, :dest, :chdir
      
          def initialize(@source : String, @dest : String, *, @chdir : String? = nil); end
    
          def execute
            if dir = chdir
              Dir.cd(dir) do
                FileUtils.ln_s(source, dest)
              end
            else
              FileUtils.ln_s(source, dest)
            end
          end
    
          def description : String
            String.build do |io|
              io << source
              io << dest
              io << chdir
            end
          end
        end
      end
    end
  end
end
