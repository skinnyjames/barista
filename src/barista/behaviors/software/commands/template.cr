require "crinja"

module Barista
  module Behaviors
    module Software
      module Commands
        class Template < Base
          getter :src, :dest, :vars, :mode
      
          def initialize(*, @dest : String, @src : String, @mode : File::Permissions, @vars : Hash(String, String)); end
    
          def execute
            template = File.read(src)
            rendered = Crinja.render(template, vars)
            File.write(dest, rendered, perm: mode)
          end
    
          def description : String
            String.build do |io|
              io << dest
              io << src
              io << mode.to_s
              vars.to_s(io)
            end
          end
        end
      end
    end
  end
end
