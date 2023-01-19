module Barista
  module Behaviors
    module Brew
      module ActionCommands
        class CommandResponse
          delegate(
            :success?,
            :exit_code,
            to: @status
          )

          getter :status, :output, :error
          
          def initialize(@status : Process::Status, @output : String, @error : String); end
        end

        include Software::Emittable
        
        def run(command : String, env : Hash(String, String)? = nil, chdir : String? = nil, as_user : String? = nil)
          output = IO::Memory.new
          error = IO::Memory.new
          status = begin
            unless as_user.nil?
              Process.run("su -c '#{command}' #{as_user}", shell: true, output: output, error: error, env: env, chdir: chdir)
            else
              Process.run(command, shell: true, output: output, error: error, env: env, chdir: chdir)
            end
          end

          CommandResponse.new(status, output.to_s.strip, error.to_s.strip)
        end

        def run(command : String, args : Array(String), env : Hash(String, String)? = nil, chdir : String? = nil, as_user : String? = nil)
          output = IO::Memory.new
          error = IO::Memory.new

          status = begin
            unless as_user.nil?
              Process.run("su", ["-c", command].concat(args), output: output, error: error, env: env, chdir: chdir)
            else
              Process.run(command, args, shell: false, output: output, error: error, env: env, chdir: chdir)
            end
          end

          CommandResponse.new(status, output.to_s.strip, error.to_s.strip)
        end

        def success?(cmd, **opts)
          run(cmd, **opts).success?
        end

        def success?(cmd, args, **opts)
          run(cmd, args, **opts).success?
        end

        def command(str : String, **args)
          Barista::Behaviors::Software::Commands::Command.new(str, **args)
            .forward_output(&on_output)
            .forward_error(&on_error)
            .execute
        end

        def copy(src, dest, **args)
          Barista::Behaviors::Software::Commands::Copy.new(src, dest, **args)
            .forward_output(&on_output)
            .forward_error(&on_error)
            .execute
        end

        def sync(src, dest, **args, &block : Merger::Strategy)
          Barista::Behaviors::Software::Commands::Sync.new(src, dest, **args, &block)
            .forward_output(&on_output)
            .forward_error(&on_error)
            .execute
        end

        def sync(src, dest, **args)
          Barista::Behaviors::Software::Commands::Sync.new(src, dest, **args)
            .forward_output(&on_output)
            .forward_error(&on_error)
            .execute
        end

        def link(src, dest, **args)
          Barista::Behaviors::Software::Commands::Link.new(src, dest, **args)
            .forward_output(&on_output)
            .forward_error(&on_error)
            .execute
        end

        def mkdir(dir, **args)
          Barista::Behaviors::Software::Commands::Mkdir.new(dir, **args)
            .forward_output(&on_output)
            .forward_error(&on_error)
            .execute
        end

        def patch(path : String, **args)
          Barista::Behaviors::Software::Commands::Patch.new(path, **args)
            .forward_output(&on_output)
            .forward_error(&on_error)
            .execute
        end

        def template(**args)
          Barista::Behaviors::Software::Commands::Template.new(**args)
            .forward_output(&on_output)
            .forward_error(&on_error)
            .execute
        end

        def block(name = nil, &block : ->)
          Barista::Behaviors::Software::Commands::Block.new(name, &block)
            .forward_output(&on_output)
            .forward_error(&on_error)
            .execute
        end

        def emit(str : String)
          Barista::Behaviors::Software::Commands::Emit.new(str).forward_output(&on_output).execute
        end

        def emit_error(str : String)
          Barista::Behaviors::Software::Commands::Emit.new(str, is_error: true).forward_error(&on_error).execute
        end
      end
    end
  end
end
