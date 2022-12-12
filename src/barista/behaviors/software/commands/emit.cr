module Barista
  module Behaviors
    module Software
      module Commands
        class Emit < Base
          getter :output, :is_error
          def initialize(@output : String, @is_error : Bool = false); end

          def execute
            if is_error
              on_error.try(&.call(output))
            else
              on_output.try(&.call(output))
            end
          end

          def description : String
            String.new do |io|
              io << output
              io << is_error
            end
          end
        end
      end
    end
  end
end
