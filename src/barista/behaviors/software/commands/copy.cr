module Barista
  module Behaviors
    module Software
      module Commands
        class Copy < Base
          getter :src, :dest, :chdir, :env
      
          def initialize(@src : String, @dest : String, @chdir : String? = nil, @env : Hash(String, String)? = nil); end
    
          def execute
            if File.directory?(src)
              c = Command.new("cp -R #{src} #{dest}", chdir: chdir, env: env)
              if o = on_output
                c.on_output(&o)
              end

              if e = on_error
                c.on_error(&e)
              end
            else
              c = Command.new("cp #{src} #{dest}", chdir: chdir, env: env)
              if o = on_output
                c.on_output(&o)
              end

              if e = on_error
                c.on_error(&e)
              end
            end
            
            c.execute
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
