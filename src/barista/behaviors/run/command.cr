module Barista
  module Behaviors
    module Run
      class ProcessCommand
        getter :command, :args, :env

        def initialize(
          @command : String,
          *,
          @task : Run::Task,
          @args : Array(String) = [] of String, 
          @env : Hash(String, String)? = nil
        )
          
          @args << ">"

          if log = task.log_location
            @args << log
            @args << "2>&1"
          else
            @args << "/dev/null"
          end

        end

        def execute : Process
          puts command, args
          Process.new("#{command} #{args.join(" ")}", env: env, shell: true, output: :close, error: :close)
        end
      end
    end
  end
end
