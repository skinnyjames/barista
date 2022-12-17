module Barista
  module Behaviors
    module Software
      class CommandError < Exception; end

      module Commands
        abstract class Base
          include Emittable
          
          # executes the command
          #
          # takes the name of the task, a `BuildMeta` for logging, and an optional file handle for logging.
          abstract def execute


          # A unique string representing this command
          #
          # used to calculate the shasum for the builder
          abstract def description : String
        end
      end
    end
  end
end
