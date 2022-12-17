module Barista
  module Behaviors
    module Software
      module OS
        class Kernel
          getter :name, :release, :version, :machine, :processor, :os

          @name : String
          @release : String
          @version : String
          @machine : String
          @processor : String
          @os : String

          def initialize
            @name = run_command("uname -s")
            @release = run_command("uname -r")
            @version = run_command("uname -v")
            @machine = run_command("uname -m")
            @processor = run_command("uname -p")
            @os = "Unknown"

            {% if flag?(:linux) %}
              @os = run_command("uname -o")
            {% elsif flag?(:darwin) %}
              @os = name
              @machine = "x86_64" if run_command("sysctl -n hw.optional.x86_64") == "1"
            {% end %}
          end

          private def run_command(cmd) : String
            output = nil
            error = nil
            command = Commands::Command.new(cmd)
            command.on_output do |str|
              output = str
            end

            command.on_error do |str|
              error = str
            end

            command.execute
            raise Exception.new("Failed to run #{cmd}: #{error}") unless error.nil?

            if o = output
              o.strip
            else
              raise Exception.new("No output for #{cmd}")
            end
          end
        end
      end
    end
  end
end
