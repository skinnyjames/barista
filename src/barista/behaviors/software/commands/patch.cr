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
            c = Command.new(cmd, chdir: chdir, env: env)
            if o = on_output
              c.on_output(&o)
            end
            if e = on_error
              c.on_error(&e)
            end
            c.execute
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
