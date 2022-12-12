require "../spec_helper"

private class SoftwareProject < Barista::Project; end

private class SoftwareTask1 < Barista::Task(SoftwareProject)
  include Barista::Behaviors::Software::Task
  
  def build : Nil

  end
end

module Barista
  module Behaviors
    module Software
      describe "Software::Task" do
        it "comes with a Fetchers::Net fetcher" do
          task = SoftwareTask1.new
          task.fetch("#{fixture_url}/test.tar.gz")
          task.fetcher.should be_a(Barista::Behaviors::Software::Fetchers::Net)
        end

        # it "exposes a series of commands" do
        #   task = SoftwareTask1.new
        #   task.command("ls")
        #   task.copy("from", "to")
        #   task.sync("from", "to")
        #   task.link("from", "to")
        #   task.patch("something.patch")
        #   task.template(
        #     source: "foo",
        #     dest: "bar",
        #     mode: File::Permissions.new(0o755)
        #     vars: { "some" => "value" }
        #   )

        #   task.commands.map(&.class).should eq([
        #     Command::Base, 
        #     Command::Copy, 
        #     Command::Sync, 
        #     Command::Link, 
        #     Command::Patch,
        #     Command::Template
        #   ])
        # end
      end
    end
  end
end
