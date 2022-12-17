require "../../spec_helper"

private class TestProject < Barista::Project
  include Barista::Behaviors::Omnibus::Project

  def initialize
    install_dir(File.join(downloads_path, "install"))
    barista_dir(File.join(downloads_path, "barista"))
  end
end

@[Barista::BelongsTo(TestProject)]
private class ConfigurableTask < Barista::Task
  include Barista::Behaviors::Omnibus::Task

  def initialize(@project : Barista::Behaviors::Omnibus::Project)
    super(project)
  end

  def build : Nil
    command("pwd")
    command("cat test.txt")
  end

  def configure : Nil
    version("foobar")
    relative_path(File.join("foo", "bar" ,"baz"))
    source(File.join(fixture_url, "test.tar.gz"))
  end
end

module Barista::Behaviors::Omnibus
  describe "Task" do
    it "conifgures on initialize" do
      task = ConfigurableTask.new(TestProject.new)
      task.version.should eq("foobar")
      task.source.try(&.uri.to_s).should eq(File.join(fixture_url, "test.tar.gz"))
    end

    it "downloads the source to a relative path and executes commands in that context" do
      output = [] of String
      error = [] of String
      ConfigurableTask.new(TestProject.new)
        .collect_output(output)
        .on_error { |str| puts str }
        .execute

      output[0].should contain("/foo/bar/baz")
      output[1].should eq("foobar")
    end
  end
end
