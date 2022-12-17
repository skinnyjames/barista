module Barista
  module Behaviors
    module Software
      module Commands
        class Patch < Base
          getter :patch_file, :plevel, :chdir, :env

          @patch : String? = nil
    
          def initialize(@patch_file : String, *, @target : String? = nil, @plevel : Int32 = 1, @chdir : String? = nil, @env : Hash(String, String)? = nil); end
    
          def execute
            cmd = "patch -p#{plevel} -i #{patch_file}"
            Command.new(cmd, chdir: chdir, env: env)
              .forward_output(&on_output)
              .forward_error(&on_error)
              .execute
          end
    
          protected def filepath
            Path[patch_file].expand
          end
    
          def description : String
            String.build do |io|
              io << File.read(filepath)
              io << plevel
              io << chdir
              env.to_s(io)
            end
          end
        end
      end
    end
  end
end
