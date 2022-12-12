require "./spec_helper"

private class OrchestratorTestProject < Barista::Project
end

private class Task1 < Barista::Task(OrchestratorTestProject)
  def initialize(@log : Barista::RichLogger); end
  getter :log

  def execute
    sleep 1
    log.info { "task1" }
  end
end

private class Task2 < Barista::Task(OrchestratorTestProject)
  def initialize(@log : Barista::RichLogger); end
  getter :log

  def execute
    log.info { "task2" }
  end
end

private class Task3 < Barista::Task(OrchestratorTestProject)
  dependency Task2

  getter :log

  def initialize(@log : Barista::RichLogger); end

  def execute
    log.info { "task3" }
  end
end

describe Barista::Orchestrator do
  it "executes the tasks in a project" do
    colors = Barista::ColorIterator.new
    project = OrchestratorTestProject.new
    registry = Barista::Registry(Barista::Task(OrchestratorTestProject)).new

    orchestrator = Barista::Orchestrator(OrchestratorTestProject).new(project.registry, workers: 3) do |constructor|
      task = constructor.new(Barista::RichLogger.new(colors.next, constructor.name))
    end

    with_io do |io|
      orchestrator.build
      io.to_s.should match(/(.)*task2(.)*task3(.)*task1/m)
    end
  end
end

