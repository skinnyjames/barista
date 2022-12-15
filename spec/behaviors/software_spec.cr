require "../spec_helper"

private class SoftwareProject < Barista::Project; end

@[Barista::BelongsTo(SoftwareProject)]
private class SoftwareTask1 < Barista::Task
  include Barista::Behaviors::Software::Task
  property :foo

  @foo = "bar"

  def build : Nil; end
end

module Barista
  module Behaviors
    module Software
      describe "Task" do
        it "exposes a series of commands" do
          task = SoftwareTask1.new
          task.command("ls")
          task.sync("from", "to")
          task.link("from", "to")
          task.mkdir("foo")
          task.patch("something.patch")
          task.template(
            src: "foo",
            dest: "bar",
            mode: File::Permissions.new(0o755),
            vars: { "some" => "value" }
          )

          task.commands.map(&.class).should eq([
            Commands::Command, 
            Commands::Sync, 
            Commands::Link,
            Commands::Mkdir,
            Commands::Patch,
            Commands::Template
          ])
        end
      end
    end
  end
end
