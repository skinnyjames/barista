module Barista
  module Behaviors
    module Brew
      module ActionCommands
        include Barista::Behaviors::Software::OS::Information

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
        
        def shellout(command : String, env : Hash(String, String)? = nil, chdir : String? = nil, as_user : String? = nil)
          output = IO::Memory.new
          error = IO::Memory.new

          if as_user
            if platform.family == "mac_os_x"
              new_command = "su #{Process.quote(command)} #{as_user}" 
            else
              new_command = "su -c #{Process.quote(command)} #{as_user}"
            end
          else
            new_command = command
          end

          status = Process.run(new_command, shell: true, output: output, error: error, env: env, chdir: chdir)
          CommandResponse.new(status, output.to_s.strip, error.to_s.strip)
        end

        def shellout(command : String, args : Array(String), env : Hash(String, String)? = nil, chdir : String? = nil, as_user : String? = nil)
          output = IO::Memory.new
          error = IO::Memory.new

          status = begin 
            if as_user
              new_command = "su"
              safe = safe_command(command, args)
              safe = Process.quote(safe) if platform.family == "mac_os_x"
              args = ["-c", safe, as_user]
              args.shift if platform.family == "mac_os_x"
              Process.run(new_command, args, shell: false, output: output, error: error, env: env, chdir: chdir)
            else
              Process.run(command, args, shell: false, output: output, error: error, env: env, chdir: chdir)
            end
          end

          CommandResponse.new(status, output.to_s.strip, error.to_s.strip)
        end

        private def safe_command(command, args = [] of String)
          cmd = command.split(" ").reject(&.blank?)
          bin = cmd.delete_at(0)
          command_args = Process.quote(Process.parse_arguments(cmd.join(" ")))
          extra_args = Process.quote(args)
          String.build do |str|
            str << "#{bin} "
            str << "#{command_args} " unless command_args.blank?
            str << "#{extra_args}" unless extra_args.blank?
          end
        end

        def success?(cmd, **opts)
          shellout(cmd, **opts).success?
        end

        def success?(cmd, args, **opts)
          shellout(cmd, args, **opts).success?
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
