module Barista
  module Behaviors
    module Brew
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
            begin
              project.run(cmd, service: service, workers: workers)
            rescue ex : NoTasks
              output.puts("<error>No tasks run #{cmd}</error>")
            end
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
    end
  end
end
