module Barista
  module Behaviors
    module Software
      module Commands
        class Copy < Base
          getter :src, :dest, :chdir, :env
      
          def initialize(@src : String, @dest : String, @chdir : String? = nil, @env : Hash(String, String)? = nil); end
    
          def execute
            cmd = File.directory?(src) ? "cp -R #{src} #{dest}" : "cp #{src} #{dest}"

            Command.new(cmd, chdir: chdir, env: env)
              .forward_output(&on_output)
              .forward_error(&on_error)
              .execute
          end
    
          def description : String
            String.build do |io|
              io << src
              io << dest
              env.to_s(io)
              io << chdir
            end
          end
        end
      end
    end
  end
end
