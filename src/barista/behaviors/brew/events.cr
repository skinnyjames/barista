module Barista
  module Behaviors
    module Brew
      module Events
        macro gen_action_event(name)
          @{{ name.id }} = ->(action : Action) {}

          def {{ name.id }}(&block : Action ->)
            @{{ name.id }} = block
          end

          def {{ name.id }} : Proc(Action, Nil)
            @{{ name.id }}
          end
        end

        gen_action_event(:on_action_start)
        gen_action_event(:on_action_skipped)
        gen_action_event(:on_action_succeed)
        gen_action_event(:on_action_failed)
        gen_action_event(:on_action_finished)

        def forward_action_events(other : Brew::Events)
          other.on_action_start do |action, skipped|
            on_action_start.call(action)
          end

          other.on_action_skipped do |action|
            :on_action_skipped.call(action)
          end

          other.on_action_succeed do |action|
            on_action_succeed.call(action)
          end

          other.on_action_failed do |action|
            on_action_failed.call(action)
          end

          other.on_action_finished do |action|
            on_action_finished.call(action)
          end
        end
      end
    end
  end
end