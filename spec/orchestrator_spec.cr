require "./spec_helper"

private class OrchestratorTestProject < Barista::Project
end

private class ErrorProject < Barista::Project; 
  include Barista::Behaviors::Software::Project
end

@[Barista::BelongsTo(ErrorProject)]
@[Barista::BelongsTo(OrchestratorTestProject)]
private class Task1 < Barista::Task
  def initialize(@log : Barista::RichLogger); 
    super()
  end
  getter :log

  def execute
    sleep 0.2
    log.info { "task1" }
  end
end

@[Barista::BelongsTo(ErrorProject)]
@[Barista::BelongsTo(OrchestratorTestProject)]
private class Task2 < Barista::Task
  def initialize(@log : Barista::RichLogger);  
    super()
  end
  getter :log

  def execute
    log.info { "task2" }
  end
end

@[Barista::BelongsTo(ErrorProject)]
@[Barista::BelongsTo(OrchestratorTestProject)]
private class Task3 < Barista::Task
  dependency Task2

  getter :log

  def initialize(@log : Barista::RichLogger);  
    super()
  end

  def execute
    log.info { "task3" }
  end
end

@[Barista::BelongsTo(ErrorProject)]
private class Task4 < Barista::Task
  include Barista::Behaviors::Software::Task
  getter :log

  def initialize(@log : Barista::RichLogger);  
    super()
  end

  def build : Nil
    block do
      command("ls")
      .on_output { |_| raise "Hello!" }
      .execute
    end
  end
end

describe Barista::Orchestrator do
  it "executes the tasks in a project" do
    colors = Barista::ColorIterator.new
    project = OrchestratorTestProject.new

    project.tasks.each do |task|
      task.new(::Barista::RichLogger.new(colors.next, task.name))
    end

    orchestrator = Barista::Orchestrator(Barista::Task).new(project.registry, workers: 3)

    with_io do |io|
      orchestrator.execute
      io.to_s.should match(/(.)*task2(.)*task3(.)*task1/m)
    end
  end

  it "exits gracefully if a command fails" do
    colors = Barista::ColorIterator.new
    project = ErrorProject.new
    output = [] of String

    project.tasks.each do |klass|
      task = klass.new(::Barista::RichLogger.new(colors.next, klass.name))

      if task.is_a?(Barista::Behaviors::Software::Task)
        task.collect_error(output)
        task.collect_output(output)
      end
    end

    orchestrator = Barista::Orchestrator(Barista::Task).new(project.registry, workers: 3)


    expect_raises(Exception, "Hello!") do
      orchestrator.execute
    end
  end
end

