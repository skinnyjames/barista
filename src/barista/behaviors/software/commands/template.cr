require "crinja"
require "json"

module Barista
  module Behaviors
    module Software
      module Commands
        class Template < Base          
          getter :src, :dest, :vars, :mode, :string

          def initialize(*, @dest : String, @src : String, @mode : File::Permissions, @vars : Hash(String, String) | Hash(String, Crinja::Value), @string : Bool = false); end

          def execute
            template = string ? src : File.read(src)
            rendered = Crinja.render(template, vars)
            
            Commands::Mkdir.new(File.dirname(dest), parents: true).execute

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
