module Barista
  module Behaviors
    module Brew
      macro gen_signal_class(klass, name, command)
        class {{ klass.id }}Action < Barista::Behaviors::Brew::Action
          nametag({{ name.id.stringify }})

          def execute
            {{ command }}
          end

          def skip? : Bool
            !process_exists?
          end

          def ready? : Bool
            skip?
          end

          def output
            task.pid_info
          end
        end
      end

      class StatusAction < Barista::Behaviors::Brew::Action
        nametag("status")

        def execute; end

        def skip? : Bool
          false
        end

        def ready? : Bool
          true
        end

        def output
          task.pid_info
        end
      end

      gen_signal_class(Stop, stop, terminate)
      gen_signal_class(Kill, kill, kill)

      module ProcessActions
        macro included
          actions(
            Barista::Behaviors::Brew::StatusAction, 
            Barista::Behaviors::Brew::StopAction,
            Barista::Behaviors::Brew::KillAction,
          )
        end
      end
    end
  end
end