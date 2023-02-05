module Barista
  module Behaviors
    module Brew
      class SupervisorCommand
        getter :command, :task, :env, :args, :as_user

        def initialize(
          @command : String,
          @args = [] of String,
          *,
          @task : Brew::Task,
          @as_user : String? = nil,
          @env : Hash(String, String)? = nil
        )
        end

        def execute
          Process.fork do
            io = init_io
            ProcessHelper.set_pgid(Process.pid, 0)
            Process.exec(eval_script, env: env, shell: true, output: io, error: io, chdir: ".")
          end
        end

        def eval_script
          "eval \"#{safe_command} 2>&1 &\" && echo $! > #{task.pid_location}"
        end

        def safe_command
          cmd = command.split(" ").reject(&.blank?)
          bin = cmd.delete_at(0)
          command_args = Process.quote(Process.parse_arguments(cmd.join(" ")))
          extra_args = Process.quote(args)
          str = String.build do |str|
            str << "#{bin} "
            str << "#{command_args} " unless command_args.blank?
            str << "#{extra_args}" unless extra_args.blank?
          end

          if user = as_user
            args = Process.quote(["-c", "\"#{str}\"", user])
            "su #{args}"
          else
            str
          end
        end

        def init_io : IO | Process::Redirect
          if log = task.log_location
            prepare_log_location(log)
            
            file = File.new(log, "a+")
            file
          else
            Process::Redirect::Close
          end
        end

        private def prepare_log_location(log)
          FileUtils.mkdir_p(File.dirname(log))

          File.write(log, "") unless File.exists?(log)
        end
      end
    end
  end
end
