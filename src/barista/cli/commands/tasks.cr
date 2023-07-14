@[ACONA::AsCommand("tasks", description: "information regarding tasks")]
class Barista::CLI::Commands::Upstreams(T) < ACON::Command
  getter :project

  protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
    output.puts(T.tasks.map(&.name).join(", "))
    ACON::Command::Status::SUCCESS
  end

  protected def configure : Nil; end
end