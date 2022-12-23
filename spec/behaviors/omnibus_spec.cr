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


private class MacroTest
  include Barista::Behaviors::Omnibus::Macros

  gen_method(:string, String) { "string" }
  gen_method(:string_override, String) { "string" }
  gen_method(:number, Int32) { 1 }
  gen_method(:number_override, Int32) { 1 }
  gen_method(:boolean, Bool) { true }
  gen_method(:boolean_inverse, Bool) { false }
  gen_method(:boolean_inverse_override, Bool) { false }
  gen_method(:boolean_override, Bool) { false }
  gen_collection_method(:apple, :apples, String)

  def initialize
    string_override("override")
    number_override(2)
    boolean_override(false)
    boolean_inverse_override(true)
    apple("foo")
    apple("bar")
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
          task.source("http://one.tar.gz")

          task2 = OmnibusTask.new(project)
          task2.command("ls")
          task2.source("http://two.tar.gz")


          task.shasum.should_not eq(task2.shasum)

          task2.source("http://one.tar.gz")

          task.shasum.should eq(task2.shasum)
        end
      end

      describe "Macros" do
        it "resolves with defaults" do
          test = MacroTest.new
          test.string.should eq("string")
          test.string_override.should eq("override")
          test.number.should eq(1)
          test.number_override.should eq(2)
          test.boolean.should eq(true)
          test.boolean_override.should eq(false)
          test.boolean_inverse_override.should eq(true)
          test.apples.should eq(%w[foo bar])
        end
      end
    end
  end
end
