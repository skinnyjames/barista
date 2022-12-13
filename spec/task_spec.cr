require "./spec_helper"

private class MockProject < Barista::Project; end

@[Project(MockProject)]
private class Task1 < Barista::Task
  def execute; end
end

@[Project(MockProject)]
private class Task2 < Barista::Task
  dependency Task1
  
  def execute; end
end

module Barista
  describe "Task" do
    it "exposes dependencies" do
      Task2.dependencies.should eq([Task1])
    end
  end
end
