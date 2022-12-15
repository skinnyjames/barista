require "../spec_helper"

private class OmnibusProject < Barista::Project; 
  include Barista::Behaviors::Omnibus::Project

  def install_dir
    "./opt/omnibus"
  end

  def barista_dir
    "./opt/barista"
  end
end

@[Barista::BelongsTo(OmnibusProject)]
private class OmnibusTask < Barista::Task
  include Barista::Behaviors::Omnibus::Task
  property :foo

  @foo = "bar"

  def initialize(@project : Barista::Behaviors::Omnibus::Project)
    super(@project)
  end

  def build : Nil
  end

  def configure : Nil
  end
end

module Barista
  module Behaviors
    module Omnibus
      describe "Task" do
        it "can get the hash of commands" do
          project = OmnibusProject.new
          task = OmnibusTask.new(project)
          task.command("ls")


          task2 = OmnibusTask.new(project)
          task2.command("ls")
          task2.command("foo")

          task.shasum.should_not eq(task2.shasum)

          task.command("foo")

          task.shasum.should eq(task2.shasum)
        end
      end
    end
  end
end
