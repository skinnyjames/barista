private class RunProject < Barista::Project
  include_behavior(Brew)

  def initialize
    process_dir("#{downloads_path}/run/process")
    log_dir("#{downloads_path}/run/log")
  end
end

@[Barista::BelongsTo(RunProject)]
private class RunTask < Barista::Task
  include_behavior(Brew)

  @@name = "run-task"

  actions Start, Stop
end

class Start < Barista::Behaviors::Brew::Action
  @@name = "start"

  wait false

  def execute
    supervise("#{fixtures_path}/brew/stub start")
  end

  def skip? : Bool
    process_exists?
  end

  def ready? : Bool
    true
  end
end

class Stop < Barista::Behaviors::Brew::Action
  @@name = "stop"

  wait false

  def execute
    File.write(pid_path, "stopped")
  end

  def skip? : Bool
    !File.exists?(pid_path)
  end

  def ready? : Bool
    true
  end

  def pid_path
    "#{task.project.process_dir}/#{task.name}.pid"
  end
end

module Barista::Behaviors::Brew
  describe "starts and tracks a process", tags: "brew" do
    it "starts and stops the command" do
      project = RunProject.new
      project.run("start", service: "run-task")
      pid_path = "#{project.process_dir}/run-task.pid"
      wait_for do
        File.exists?(pid_path)
      end
      File.read(pid_path).strip.should_not eq("")
      project.run("stop", service: "run-task")
      File.read(pid_path).strip.should eq("stopped")
      wait_for do
        File.read("#{project.log_dir}/run-task.log").strip == "start"
      end
    end
  end
end