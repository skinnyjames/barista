require "../../spec_helper"

private class TestProject < Barista::Project
  include Barista::Behaviors::Omnibus::Project
end

@[Barista::BelongsTo(TestProject)]
private class ConfigurableTask < Barista::Task
  include Barista::Behaviors::Omnibus::Task

  def initialize(@project : Barista::Behaviors::Omnibus::Project)
    super(project)
  end

  def build : Nil
  end

  def configure : Nil
    version("foobar")
    source(File.join(fixture_url, "files", "test.tar.gz"))
  end
end

module Barista::Behaviors::Omnibus
  describe "Task" do
    it "conifgures on initialize" do
      task = ConfigurableTask.new(TestProject.new)
      task.version.should eq("foobar")
      task.source.try(&.uri.to_s).should eq(File.join(fixture_url, "files", "test.tar.gz"))
    end
  end
end
