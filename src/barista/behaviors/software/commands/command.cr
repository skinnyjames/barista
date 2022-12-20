module Barista
  module Behaviors
    module Software
      module Commands
        class Command < Base
          getter :command, :chdir, :env

          def initialize(@command : String, *, @chdir : String? = nil, @env : Hash(String, String)? = nil); end

          def execute
            process = Process.new(command, chdir: chdir, shell: true, env: env, output: :pipe, error: :pipe)
            done = Channel(Nil).new
            err = nil

            spawn do
              while process.exists? && (line = process.output?.try(&.gets))
                begin
                  on_output.call(line)
                rescue ex
                  err = ex
                end
              end
              
              done.send(nil)
            end
    
            spawn do
              while process.exists? && (line = process.error?.try(&.gets))
                begin
                  on_error.call(line)
                rescue ex
                  err = ex
                end
              end
              
              done.send(nil)
            end

            status = process.wait

            2.times { done.receive }

            if e = err
              raise CommandError.new("Command failed while emitting output: #{e}")
            else
              # raise error if status code isn't 0
              raise CommandError.new("Command failed with exit #{status.exit_code}") unless status.success?
            end
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
