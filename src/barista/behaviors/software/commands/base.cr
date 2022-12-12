module Barista
  module Behaviors
    module Software
      class CommandError < Exception; end

      module Commands
        abstract class Base
          getter :on_output, :on_error

          @on_output : Proc(String, Nil)?
          @on_error : Proc(String, Nil)?
          
          # executes the command
          #
          # takes the name of the task, a `BuildMeta` for logging, and an optional file handle for logging.
          abstract def execute

          def on_output(&block : String -> Nil)
            @on_output = block
            self
          end

          def on_error(&block : String -> Nil)
            @on_error = block
            self
          end
          
          # A unique string representing this command
          #
          # used to calculate the shasum for the builder
          abstract def description : String
        end
      end
    end
  end
end
