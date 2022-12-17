module Barista
  module Behaviors
    module Software
      module Commands
        class Command < Base
          getter :command, :chdir, :env

          def initialize(@command : String, *, @chdir : String? = nil, @env : Hash(String, String)? = nil); end

          def execute
            process = Process.new(command, chdir: chdir, shell: true, env: env, output: :pipe, error: :pipe)
            
            spawn do
              while line = process.output.gets
                on_output.call(line)
              end
            end
    
            spawn do
              while line = process.error.gets
                on_error.call(line)
              end
            end
    
            status = process.wait
            # raise error if status code isn't 0
            raise CommandError.new("Command failed with exit #{status.exit_code}") unless status.success?
          end

          def description : String
            String.build do |io|
              io << command
              io << chdir
              env.to_s(io) if env
            end
          end
        end
      end
    end
  end
end
