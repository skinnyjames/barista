require "../../../spec_helper"

private class OSProject < Barista::Project
  include Barista::Behaviors::Software::Project
end

@[Barista::BelongsTo(OSProject)]
private class OSTask < Barista::Task
  include Barista::Behaviors::Software::Task
  def build : Nil
    emit("PLATFORM=#{platform.name}")
    emit("PLATFORM_VERSION=#{platform.version}")
    emit("PLATFORM_FAMILY=#{platform.family}")
    emit("CPUS=#{memory.cpus}")
  end
end

module Barista::Behaviors::Software::OS
  describe "Information" do
    it "provides os specific information" do
      log = [] of String

      project = OSProject.new
      task = OSTask.new
              .collect_output(log)

      {% if flag?(:linux) %}
        [project, task].each do |p|
          p.platform.should be_a(Barista::Behaviors::Software::OS::Linux::Platform)
          p.memory.should be_a(Barista::Behaviors::Software::OS::Linux::Memory)
        end
      {% elsif flag?(:darwin) %}
        [project, task].each do |p|
          p.platform.should be_a(Barista::Behaviors::Software::OS::Darwin::Platform)
          p.memory.should be_a(Barista::Behaviors::Software::OS::Darwin::Memory)
        end
      {% end %}

      task.execute
        
      wait_for do
        log.size == 4
      end

      log[0].should match(/PLATFORM=\w+/)
      log[1].should match(/PLATFORM_VERSION=\w+/)
      log[2].should match(/PLATFORM_FAMILY=\w+/)
      log[3].should match(/CPUS=\d+/)
    end

    it "provides kernel info" do
      project = OSProject.new
      task = OSTask.new

      project.kernel.name.should_not eq(nil)
      project.kernel.version.should_not eq(nil)
      project.kernel.machine.should_not eq(nil)
      project.kernel.release.should_not eq(nil)
      project.kernel.processor.should_not eq(nil)
    end
  end
end