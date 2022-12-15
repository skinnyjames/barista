require "./spec_helper"

private class MockProject < Barista::Project
end

@[Barista::BelongsTo(MockProject)]
private class MockTask1 < Barista::Task
  def execute; end
end

@[Barista::BelongsTo(MockProject)]
private class MockTask2 < Barista::Task
  def execute; end
  def self.name
    "foobar"
  end
end

module Barista
  describe Project do
    it "stores an array of tasks declared around it" do
      MockProject.tasks.should eq([MockTask1, MockTask2])
      project = MockProject.new
      project.tasks.each(&.new)
      project.registry.tasks.should be_a(Array(Barista::Task))
    end
  end
end
