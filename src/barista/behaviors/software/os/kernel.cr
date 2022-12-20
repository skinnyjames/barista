module Barista
  module Behaviors
    module Software
      module OS
        class Kernel
          getter :name, :release, :version, :machine, :processor, :os

          @name : String?
          @release : String?
          @version : String?
          @machine : String?
          @processor : String?
          @os : String?

          def name : String
            @name ||= run_command("uname -s")
          end

          def release : String
            @release ||= run_command("uname -r")
          end

          def version : String
            @version ||= run_command("uname -v")
          end

          def machine : String
            @machine ||= begin
              machine = run_command("uname -m")
              {% if flag?(:darwin) %}
                machine = "x86_64" if run_command("sysctl -n hw.optional.x86_64") == "1"
              {% end %}
              machine
            end
          end

          def processor : String
            @processor ||= run_command("uname -p")
          end

          def os : String
            {% if flag?(:darwin) %}
              @os ||= name
            {% else %}
              @os ||= run_command("uname -o")
            {% end %}
          end

          private def run_command(cmd) : String
            output = [] of String
            error = [] of String
            command = Commands::Command.new(cmd)
              .collect_output(output)
              .collect_error(error)
              .execute

            raise Exception.new("Failed to run #{cmd}: #{error}") unless error.empty?

            unless output.join("").blank?
              output.reject(&.blank?).last
            else
              raise Exception.new("No output for #{cmd}")
            end
          end
        end
      end
    end
  end
end
