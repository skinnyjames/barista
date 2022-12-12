class Barista::CLI::Commands::Upstreams(T) < ACON::Command
  getter :registry

  @@default_name = "upstreams"

  def initialize(@registry : Barista::Registry(Barista::Task(T).class)); 
    super()
  end

  protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
    if task = input.argument("task")
      output.puts(registry.upstreams(task).map(&.name).join(", "))
    end

    ACON::Command::Status::SUCCESS
  end

  protected def configure : Nil
    self
      .argument("task", :required, "The name of the task")
  end
end