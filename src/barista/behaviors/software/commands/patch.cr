module Barista
  module Behaviors
    module Software
      module Commands
        class Patch < Base
          getter :patch_file, :plevel, :chdir, :env, :string

          @patch : String? = nil
    
          def initialize(@patch_file : String, *, @target : String? = nil, @plevel : Int32 = 1, @chdir : String? = nil, @env : Hash(String, String)? = nil, @string : Bool = false); end
    
          def execute
            file = nil
            if string
              file = write_patch_file
              cmd = "patch -p#{plevel} -i #{file.path}"
            else
              cmd = "patch -p#{plevel} -i #{patch_file}"
            end
            Command.new(cmd, chdir: chdir, env: env)
              .forward_output(&on_output)
              .forward_error(&on_error)
              .execute

            file.try(&.delete)
          end

          protected def write_patch_file
            File.tempfile("patch") do |f|
              f << patch_file
            end
          end
    
          def description : String
            String.build do |io|
              io << string ? patch_file : File.read(Path[patch_file].expand)
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
