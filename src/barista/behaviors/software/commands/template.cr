require "crinja"
require "json"

module Barista
  module Behaviors
    module Software
      module Commands
        class Template < Base          
          getter :src, :dest, :vars, :mode, :string, :config

          def initialize(*, @dest : String, @src : String, @mode : File::Permissions, @vars : Hash(String, String) | Hash(String, Crinja::Value), @string : Bool = false)
            @config = Crinja::Config.new(trim_blocks: true, lstrip_blocks: false, keep_trailing_newline: true)
          end

          def execute
            template = string ? src : File.read(src)
            rendered = crinja.from_string(template).render(vars)
            
            Commands::Mkdir.new(File.dirname(dest), parents: true)
              .forward_output(&on_output)
              .forward_error(&on_error)
              .execute

            File.write(dest, rendered, perm: mode)
          end

          def crinja
            Crinja.new(config)
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
