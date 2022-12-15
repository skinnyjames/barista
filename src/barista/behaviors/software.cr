require "openssl"
require "./software/**"

module Barista
  module Behaviors
    module Software
      module Project;
        include OS::Information
        
        def console_application
          app = super
          
        end
      end

      module Task
        include GenericCommands
        include OS::Information

        getter :on_output, :on_error, :commands
        @software_source : Fetchers::Net? = nil
        @on_output : Proc(String, Nil) = ->(str : String) { puts str }
        @on_error : Proc(String, Nil) = ->(err : String) { puts err }
  
        @commands : Array(Barista::Behaviors::Software::Commands::Base) = [] of Barista::Behaviors::Software::Commands::Base

        def execute
          build

          commands.map(&.execute)
        end

        def command(str : String, **args)
          push_command(Commands::Command.new(str, **args)
            .on_output(&on_output)
            .on_error(&on_error))
        end

        def copy(src, dest, **args)
          push_command(Commands::Copy.new(src, dest, **args)
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

        def link(src, dest, **args)
          push_command(Commands::Link.new(src, dest, **args)
            .on_output(&on_output)
            .on_error(&on_error))
        end

        def mkdir(dir, **args)
          push_command(Commands::Mkdir.new(dir, **args)
            .on_output(&on_output)
            .on_error(&on_error))
        end

        def patch(path : String, **args)
          push_command(Commands::Patch.new(path, **args)
            .on_output(&on_output)
            .on_error(&on_error))
        end

        def template(**args)
          push_command(Commands::Template.new(**args)
            .on_output(&on_output)
            .on_error(&on_error))
        end

        def block(name = nil, &block : ->)
          push_command(Commands::Block.new(name, &block)
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
          command
        end
      end
    end
  end
end
