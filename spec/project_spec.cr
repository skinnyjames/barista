require "./spec_helper"

private class MockProject < Barista::Project
  nametag("mock-project")
end

@[Barista::BelongsTo(MockProject)]
private class MockTask1 < Barista::Task
  def execute; end
end

@[Barista::BelongsTo(MockProject)]
private class MockTask2 < Barista::Task
  def execute; end
  nametag("foo")
end

@[Barista::BelongsTo(MockProject)]
private class MockTask3 < Barista::Task
  nametag("bar")
  def execute; end
end

module Barista
  describe Project do
    it "stores an array of tasks declared around it" do
      MockProject.tasks.should eq([MockTask1, MockTask2, MockTask3])
      project = MockProject.new
      project.tasks.each(&.new)
      project.registry.tasks.should be_a(Array(Barista::Task))
    end

    it "can nametag a Project" do
      MockProject.name.should eq("mock-project")
    end

    it "returns the name via class var, class method, or nametag macro" do
      project = MockProject.new
      project.tasks.map(&.new.name).should eq(["MockTask1", "foo", "bar"])
    end
  end
end
