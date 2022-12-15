require "./spec_helper"

private class MockProject < Barista::Project; end

@[Barista::BelongsTo(MockProject)]
private class Task1 < Barista::Task
  def execute; end
end

@[Barista::BelongsTo(MockProject)]
private class Task2 < Barista::Task
  dependency Task1
  
  def execute; end
end

module Barista
  describe "Task" do
    it "exposes dependencies" do
      Task2.dependencies.should eq([Task1])
    end

    it "registers instances on #new" do
      Task2.new

      MockProject.registry.tasks.map(&.name).should eq(["Task2"])
    end
  end
end
