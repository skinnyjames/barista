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

        def forward_output(&block : String ->)
          @on_output = ->(str : String) { block.call(str) }
          self
        end

        def forward_error(&block : String ->)
          @on_error = ->(str : String) { block.call(str) }
          self
        end

        def collect_output(arr : Array(String))
          @on_output = ->(str : String) { arr << str }
          self
        end

        def collect_error(arr : Array(String))
          @on_error = ->(str : String) { arr << str}
          self
        end
      end
    end
  end
end
