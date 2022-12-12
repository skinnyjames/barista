module Barista
  module Behaviors
    module Software
      module Project; 
        def console_application
          app = super
          
        end
      end

      module Task
        getter :on_output, :on_error, :commands
        @software_source : Fetchers::Net? = nil
        @on_output : Proc(String, Nil) = ->(str : String) { puts str }
        @on_error : Proc(String, Nil) = ->(err : String) { puts err }
  
        @commands : Array(Commands::Base) = [] of Commands::Base

        # Define the source code to fetch when building this project
        # 
        # Currently only supports `Barista::Behaviors::Omnibus::Fetchers::Net`
        def fetch(url : String, **opts)
          @software_source = Fetchers::Net.new(url, **opts)

          self
        end

        def execute
          build

          commands.map(&.execute)
        end

        # Returns a configured fetcher if one exists.
        def fetcher : Fetchers::Net?
          @software_source
        end

        def command(str : String, **args)
          push_command(Commands::Command.new(str, **args)
            .on_output(&on_output)
            .on_error(&on_error))
        end

        def sync(src, dest, **args, &block)
          push_command(Commands::Sync.new(src, dest, **args, &block)
            .on_output(&on_output)
            .on_error(&on_error))
        end

        def sync(src, dest, **args)
          push_command(Commands::Sync.new(src, dest, **args)
            .on_output(&on_output)
            .on_error(&on_error))
        end

        def emit(str : String)
          push_command(Commands::Emit.new(str).on_output(&on_output))
        end

        def emit_error(str : String)
          push_command(Commands::Emit.new(str, is_error: true).on_error(&on_error))
        end

        def on_output(&block : String -> Nil)
          @on_output = block
        end

        def on_error(&block : String -> Nil)
          @on_error = block
        end

        abstract def build : Nil

        protected def push_command(command : Commands::Base)
          @commands << command
        end
      end
    end
  end
end
