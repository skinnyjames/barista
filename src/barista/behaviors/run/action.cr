require "./command"

module Barista
  module Behaviors
    module Run
      class CliCommand < ACON::Command
        @@default_name = "run"

        getter :project

        def initialize(@project : Project)
          super()
        end

        protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
          workers = input.option("workers", Int32?) || 1
          command = input.argument("action")
          service = input.argument("service")

          if cmd = command
            project.run(cmd, service: service, workers: workers)
            ACON::Command::Status::SUCCESS
          end
          ACON::Command::Status::SUCCESS
        end

        def configure : Nil
          self
            .option("workers", "w", :optional, "number of workers to use")
            .argument("action", :optional, "the command to run")
            .argument("service", :optional, "a filtered service")
        end
      end

      module Project
        include Macros
        include FileUtils

        def run(command, *, workers : Int32 = 1, service : String? = nil)
          puts command
          tasks.each do |task|
            task.new(self, command)
          end
      
          Barista::Orchestrator.new(registry, filter: service.try(&.split(","))).execute
        end

        macro included 
          def console_application
            app = previous_def
            app.add(Barista::Behaviors::Run::CliCommand.new(self))
            app.default_command("run", true)
            app
          end
        end

        gen_method(:log_dir, String?) { nil }
        gen_method(:process_dir, String) { missing_attribute("process_dir") }
      end

      module TaskClassMethods
        def actions(actions : Array(Barista::Behaviors::Run::Action.class))
          actions.each do |action|
            @@actions[action.name] = action
          end
        end
      end

      module Task
        include FileUtils

        macro included
          @@actions = {} of String => Barista::Behaviors::Run::Action.class
          getter :actions
          extend Barista::Behaviors::Run::TaskClassMethods
        end

        getter :project

        def initialize(@project : Barista::Behaviors::Run::Project, @action : String)
          configure
          super()
        end

        include Macros

        getter :action

        gen_method(:binary_location, String) { missing_attribute("binary") }
        gen_method(:restart_on_failure, Bool) { true }

        abstract def configure

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
          raise Exception.new("timed out after #{duration}")
        end

        def log_location : String?
          project.log_dir.try do |dir|
            File.join(dir, name)
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
          return if runnable.skip?

          project.log_dir.try do |dir|
            mkdir_p(dir)

            log_location.try do |log|
              touch(log) unless File.exists?(log)
            end
          end

          value = runnable.execute

          if value.is_a?(Process)
            handle_peristence(value)
          end

          if runnable.class.wait
            wait_for do
              runnable.skip?
            end
          end
        end

        def pid : Int64?
          if File.exists?("#{project.process_dir}/#{name}/pid")
            File.read("#{project.process_dir}/#{name}/pid").try(&.to_i64)
          end
        end

        def pgid : Int64?
          pid.try do |id|
            pgid = Process.pgid(id)
            return pgid unless pgid.zero?
          end
        end

        private def handle_peristence(process)
          mkdir_p("#{project.process_dir}/#{name}")
          File.write("#{project.process_dir}/#{name}/pid", process.pid)
        end
      end

      abstract class Action
        include Macros

        getter :task, :command

        @@name : String?
        @command : ProcessCommand? = nil
        
        delegate(
          action, 
          binary_location,
          project,
          to: @task
        )

        macro signal(method, signal)
          def {{ method }}
            task.pgid.try do |id|
              Process.signal(Signal::{{ signal }}, -id)
            end
          end
        end

        gen_class_method(:wait, Bool) { true }

        def initialize(@task : Barista::Behaviors::Run::Task); end

        signal(quit, QUIT)
        signal(term, TERM)
        signal(kill, KILL)

        def run(command)
          ProcessCommand.new(binary_location, args: [command], task: task).execute
        end

        def action(action : Barista::Behaviors::Run::Action.class)
          task.run(action)
        end

        def self.name : String
          @@name || {{ @type.id }}.name
        end

        def name : String
          self.class.name
        end

        def process_exists?
          task.pid.try { |pid| Process.exists?(pid) } || false
        end

        abstract def skip? : Bool
        abstract def execute
      end

      abstract class StartAction < Action
        abstract def execute : Process
      end

      abstract class StopAction < Action; end
    end
  end
end