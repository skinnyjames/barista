module Barista
  module Behaviors
    module Brew
      module TaskClassMethods
        def actions(*actions)
          actions.to_a.each do |action|
            @@actions[action.name] = action
          end
        end
      end

      module Task
        include FileUtils
        include Software::Emittable
        include Software::FileMacros

        delegate(
          :on_action_skipped,
          :on_action_start,
          :on_action_succeed,
          :on_action_failed,
          :on_action_finished,
          to: @project
        )

        macro included
          @@actions = {} of String => Barista::Behaviors::Brew::Action.class
          getter :actions
          extend Barista::Behaviors::Brew::TaskClassMethods
        end

        getter :project, :action

        def initialize(@project : Barista::Behaviors::Brew::Project, @action : String)
          super()
        end

        def runnable?
          !@@actions[action]?.nil?
        end

        include Macros

        getter :action

        def execute : Nil
          run(action)
        end

        def wait_for(duration : Int32 = 5, *, interval : Float64 = 0.5, &block : -> Bool)
          time = Time.local
          while (Time.local - time).seconds < duration
            begin
              result = yield
              return if result
              sleep interval
            rescue ex : Exception
              sleep interval
            end
          end
          raise Exception.new("#{name} #{action} timed out after #{duration}")
        end

        def log_location : String?
          project.log_dir.try do |dir|
            File.join(dir, "#{name}.log")
          end
        end

        def run(action : Action.class)
          run(action.name)
        end

        def run(action : String)
          klass = @@actions[action]?

          if runnable = klass
            run(runnable.new(self))
          end
        end

        def run(runnable : Action)
          runnable.forward_output { |str| on_output.call(str) }
          runnable.forward_error { |str| on_error.call(str) }

          if runnable.skip?
            on_action_skipped.call(runnable)
            return
          end

          project.log_dir.try do |dir|
            mkdir_p(dir)

            log_location.try do |log|
              File.write(log, "") unless File.exists?(log)
            end
          end

          on_action_start.call(runnable)
          value = runnable.execute
         
          if value.is_a?(SupervisorCommand)
            value.execute
          end

          if runnable.class.wait
            begin
              duration = runnable.class.wait_duration
              interval = runnable.class.wait_interval

              wait_for(duration, interval: interval) do
                runnable.ready?
              end
              on_action_succeed.call(runnable)
            rescue ex
              on_action_failed.call(runnable)
              raise ex
            ensure
              on_action_finished.call(runnable)
            end
          end
        end

        def pid : Int64?
          if File.exists?("#{project.process_dir}/#{name}.pid")
            File.read("#{project.process_dir}/#{name}.pid").try(&.to_i64)
          end
        end

        def pgid : Int64?
          pid.try do |id|
            begin
              pgid = Process.pgid(id)
            rescue ex
              nil
            end
            
            return pgid unless pgid.try(&.zero?)
          end
        end

        def pid_info
          process_exists? ? "up [PID: #{pid}]" : "down [was PID: #{pid}]"
        end

        def process_exists?
          pid.try { |pid| Process.exists?(pid) } || false
        end

        def pid_location
          mkdir_p(project.process_dir)
          "#{project.process_dir}/#{name}.pid"
        end
      end
    end
  end
end
