module Barista
  module Behaviors
    module Brew
      struct Recipe
        getter :actions

        @actions : Hash(String, Array(String)?)

        def initialize
          @actions = {} of String => Array(String)?
        end

        def action(command, *, only : Array(String)? = nil)
          @actions[command] = only
        end
      end
    end
  end
end