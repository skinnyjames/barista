require "./spec_helper"

private class MockProject < Barista::Project
end

private class MockTask1 < Barista::Task(MockProject)
  def execute; end
end

private class MockTask2 < Barista::Task(MockProject)
  def execute; end
  def self.name
    "foobar"
  end
end

module Barista
  describe Project do
    it "stores an array of tasks declared around it" do
      MockProject.registry.tasks.should eq([MockTask1, MockTask2])
    end
  end
end
