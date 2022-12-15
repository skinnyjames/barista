require "./spec_helper"

private class OrchestratorTestProject < Barista::Project
end

@[Project(OrchestratorTestProject)]
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

@[Project(OrchestratorTestProject)]
private class Task2 < Barista::Task
  def initialize(@log : Barista::RichLogger);  
    super()
  end
  getter :log

  def execute
    log.info { "task2" }
  end
end

@[Project(OrchestratorTestProject)]
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
end

