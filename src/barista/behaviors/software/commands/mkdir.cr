module Barista
  module Behaviors
    module Software
      module Commands
        class Mkdir < Base
          getter :directory, :parents
      
          def initialize(@directory : String, *, @parents : Bool = true); end
    
          def execute
            parents ? FileUtils.mkdir_p(directory) : FileUtils.mkdir(directory)
          end

          def description : String
            String.build do |io|
              io << directory
              io << " parents : #{parents}"
            end
          end
        end
      end
    end
  end
end
