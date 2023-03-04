require "../../spec_helper"

private class TestProject < Barista::Project
  include Barista::Behaviors::Omnibus::Project

  def initialize
    install_dir(File.join(downloads_path, "install-task"))
    barista_dir(File.join(downloads_path, "barista-task"))
    cache(true)
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

@[Barista::BelongsTo(TestProject)]
private class StagingTask < Barista::Task
  include Barista::Behaviors::Omnibus::Task

  @@name = "testing"

  def initialize(@project : Barista::Behaviors::Omnibus::Project)
    super(project)
  end

  def build : Nil
    dir = File.join(smart_install_dir, "embedded", "bin")

    mkdir(dir, parents: true)
    command("echo \"foobar\" > #{dir}/test.txt")
  end

  def configure : Nil
    version("staging")
  end
end

module Barista::Behaviors::Omnibus
  describe "Task" do
    it "conifgures on initialize" do
      task = ConfigurableTask.new(TestProject.new)
      task.version.should eq("foobar")
      task.source.try(&.location).should eq(File.join(fixture_url, "test.tar.gz"))
    end

    it "downloads the source to a relative path and executes commands in that context" do
      output = [] of String
      error = [] of String
      ConfigurableTask.new(TestProject.new)
        .collect_output(output)
        .on_error { |str| puts str }
        .execute

      output[1].should contain("/foo/bar/baz")
      output[2].should eq("foobar")
    end

    it "syncs the stage correctly" do
      output = [] of String
      error = [] of String
      project = TestProject.new
      task = StagingTask.new(project)
        .collect_output(output)
        .on_error { |str| puts str }

      task.execute

      test_file = File.join(task.install_dir, "embedded", "bin", "test.txt")
      wrong_test_file = File.join(task.install_dir, task.install_dir, "embedded", "bin", "test.txt")
      File.exists?(wrong_test_file).should eq(false)
      File.exists?(test_file).should eq(true)
    end
  end
end
