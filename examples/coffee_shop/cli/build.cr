class Build < ACON::Command
  @@default_name = "build"

  getter :project
  
  def initialize(@project : Barista::Behaviors::Omnibus::Project); 
    super()
  end
  
  protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
    workers = input.option("workers")
    filter = input.option("filter").try(&.split(","))

    if workers = input.option("workers")
      project.build(workers: workers.to_i32, filter: filter)
    else
      project.build(filter: filter)
    end

    ACON::Command::Status::SUCCESS
  end

  def configure : Nil
    self
      .description("build this software")
      .option("workers", "w", :required, "The number of concurrent build workers")
      .option("filter", "f", :required, "A comma delimited list of tasks to build")
  end
end
