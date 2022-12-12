require "./spec_helper"

private class MockProject < Barista::Project; end

private class Task1 < Barista::Task(MockProject)
  def execute; end
end

private class Task2 < Barista::Task(MockProject)
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
