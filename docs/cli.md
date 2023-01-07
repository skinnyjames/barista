# Exposing a CLI

Barista is bundles the wonderful [Athena Console](https://athenaframework.org/Console/) to provide CLI functionality.

`Barista::Project#console_application` returns an [Console application](https://athenaframework.org/Console/Application/) that comes with a command to return the task list for that project.

We can add more commands by writing a new [ACON::Command](https://athenaframework.org/Console/Command/) and adding it to the project's console application.

!!! info
    
    Commands can be initialized with state specific to that project.

    Tasks can be initialized with state that is derived from CLI arguments

## Example

```crystal
class RunCommand < ACON::Command
  getter :project

  @@default_name = "run"

  def initialize(@project : Barista::Project)
    super()
  end
  
  protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status) : ACON::Command::Status
    workers = input.option("workers", Int32?) || available_cpus

    begin
      project.build(workers: workers)
      ACON::Command::Status::SUCCESS
    rescue ex
      output.puts("<error>Failed to build tasks: #{ex.message}</error>")
      ACON::Command::Status::FAILURE
    end
  end

  protected def configure : Nil
    self
      .help("execute this project's tasks")
      .option("workers", "w", :optional, "The number of concurrent build workers to use (default #{available_cpus})")
  end

  private def available_cpus
    project.memory.cpus.try(&.-(1)) || 1
  end
end


class Coffeeshop < Barista::Project
  def build(workers : Int32)
    tasks.each(&.new)

    Barista::Orchestrator(Barista::Task).new(workers: workers).execute
  end

  def console_application
    app = previous_def
    app.add(RunCommand.new(self))
    app
  end
end

Coffeeshop.new.console_application.run
```

For more information, please visit the [Athena Console](https://athenaframework.org/Console/) documentation.