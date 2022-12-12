module Barista
  module Behaviors
    module Software
      module Commands
        class Command < Base
          getter :command, :chdir, :env

          def initialize(@command : String, *, @chdir : String? = nil, @env : Hash(String, String)? = nil); end

          def execute
            try_out("Starting command: #{command}")

            process = Process.new(command, chdir: chdir, shell: true, env: env, output: :pipe, error: :pipe)
            
            spawn do
              while line = process.output.gets
                try_out(line)
              end
            end
    
            spawn do
              while line = process.error.gets
                try_error(line)
              end
            end
    
            status = process.wait
            try_out("Command exited with #{status.exit_code}")

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

          protected def try_out(string : String)
            on_output.try do |output|
              output.call(string)
            end
          end

          protected def try_error(string : String)
            on_error.try do |error|
              error.call(string)
            end
          end
        end
      end
    end
  end
end
