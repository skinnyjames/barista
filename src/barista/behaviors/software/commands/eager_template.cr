require "crinja"

module Barista
  module Behaviors
    module Software
      module Commands
        class EagerTemplate < Base          
          getter :src, :dest, :vars, :mode, template

          @template : String

          macro eager_file(filepath)
            {{ read_file(filepath) }}
          end
      
          def initialize(*, @dest : String, @src : String, @mode : File::Permissions, @vars : Hash(String, String) | Hash(String, Crinja::Value), @template = eager_file(@src)); end
    
          def execute
            rendered = Crinja.render(template, vars)
            Commands::Mkdir.new(File.dirname(dest), parents: true).execute

            File.write(dest, rendered, perm: mode)
          end
    
          def description : String
            String.build do |io|
              io << dest
              io << src
              io << template
              io << mode.to_s
              vars.to_s(io)
            end
          end
        end
      end
    end
  end
end
