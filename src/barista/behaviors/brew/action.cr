require "./supervisor_command"
require "./action_commands"

module Barista
  module Behaviors
    module Brew
      abstract class Action
        include Macros
        include ActionCommands

        getter :task, :command

        @@name : String?
        
        delegate(
          action, 
          project,
          process_exists?,
          to: @task
        )

        macro signal(method, signal)
          def {{ method }}(group = true)
            if group
              task.pgid.try do |id|
                Process.signal(Signal::{{ signal }}, -id)
              end
            else
              task.pid.try do |id|
                Process.signal(Signal::{{ signal }}, id)
              end
            end
          end
        end

        gen_class_method(:wait, Bool) { true }
        gen_class_method(:wait_duration, Int32) { 5 }
        gen_class_method(:wait_interval, Float64) { 0.5 }

        def initialize(@task : Barista::Behaviors::Brew::Task); end

        signal(stop, STOP)
        signal(quit, QUIT)
        signal(terminate, TERM)
        signal(kill, KILL)

        def supervise(command, args = [] of String, *, env : Hash(String, String)? = nil) : SupervisorCommand
          SupervisorCommand.new(command, args, task: task, env: env)
        end

        def http_ok?(url) : Bool
          HTTP::Client.get(url).success?
        end

        macro nametag(name)
          @@name = {{ name }}
        end

        def self.name
          @@name || {{ @type.id.stringify }}
        end

        def name : String
          self.class.name
        end

        abstract def skip? : Bool
        abstract def ready? : Bool
        abstract def execute

        def output : String?
          nil
        end 
      end
    end
  end
end