require "openssl"
require "./software/**"

module Barista
  module Behaviors
    module Software
      module Project
        include OS::Information
        include GenericCommands
        
        def console_application
          app = super
          
        end
      end

      module Task
        include GenericCommands
        include OS::Information
        include Emittable

        @@files = {} of String => String

        macro file(key, path)
          @@files[{{key}}] = {{ read_file(path) }}
        end

        getter :commands
        @software_source : Fetchers::Net? = nil
        @commands : Array(Barista::Behaviors::Software::Commands::Base) = [] of Barista::Behaviors::Software::Commands::Base

        def execute
          build

          commands.map(&.execute)
        end

        def file(key : String)
          @@files[key]
        end

        def command(str : String, **args)
          push_command(Commands::Command.new(str, **args)
            .forward_output(&on_output)
            .forward_error(&on_error))
        end

        def copy(src, dest, **args)
          push_command(Commands::Copy.new(src, dest, **args)
            .forward_output(&on_output)
            .forward_error(&on_error))
        end

        def sync(src, dest, **args, &block)
          push_command(Commands::Sync.new(src, dest, **args, &block)
            .forward_output(&on_output)
            .forward_error(&on_error))
        end

        def sync(src, dest, **args)
          push_command(Commands::Sync.new(src, dest, **args)
            .forward_output(&on_output)
            .forward_error(&on_error))
        end

        def link(src, dest, **args)
          push_command(Commands::Link.new(src, dest, **args)
            .forward_output(&on_output)
            .forward_error(&on_error))
        end

        def mkdir(dir, **args)
          push_command(Commands::Mkdir.new(dir, **args)
            .forward_output(&on_output)
            .forward_error(&on_error))
        end

        def patch(path : String, **args)
          push_command(Commands::Patch.new(path, **args)
            .forward_output(&on_output)
            .forward_error(&on_error))
        end

        def template(**args)
          push_command(Commands::Template.new(**args)
            .forward_output(&on_output)
            .forward_error(&on_error))
        end

        def block(name = nil, &block : ->)
          push_command(Commands::Block.new(name, &block)
            .forward_output(&on_output)
            .forward_error(&on_error))
        end

        def emit(str : String)
          push_command(Commands::Emit.new(str).forward_output(&on_output))
        end

        def emit_error(str : String)
          push_command(Commands::Emit.new(str, is_error: true).forward_error(&on_error))
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
