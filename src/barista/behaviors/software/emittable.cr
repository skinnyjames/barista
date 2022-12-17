module Barista
  module Behaviors
    module Software
      module Emittable
        getter :on_output, :on_error

        @on_output : Proc(String, Nil) = ->(str : String) { }
        @on_error : Proc(String, Nil) = ->(str : String) { }

        def on_output(&block : String -> Nil)
          @on_output = block
          self
        end

        def on_error(&block : String -> Nil)
          @on_error = block
          self
        end
      end
    end
  end
end
