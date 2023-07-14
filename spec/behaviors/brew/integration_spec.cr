require "../../spec_helper"
require "./project.cr"

private def with_project
  project = Brew::Fixture::Project.new
  begin
    yield project
  ensure
    project.try(&.run("stop"))
  end
end

module Barista::Behaviors::Brew
  describe "Integration", tags: "brew" do
    it "dependencies are preserved" do
      with_project do |project|  
        action_start = [] of String
        action_failed = [] of String
        action_skipped = [] of String
        action_succeed = [] of String
        action_finished = [] of String

        project.on_action_start do |a|
          action_start << "#{a.task.name}> #{(a.output || a.name)}"
        end

        project.on_action_skipped do |a|
          action_skipped << "#{a.task.name}> #{(a.output || a.name)}"
        end

        project.on_action_succeed do |a|
          action_succeed << "#{a.task.name}> #{(a.output || a.name)}"
        end
        
        project.on_action_failed do |a|
          action_failed << "#{a.task.name}> #{(a.output || a.name)}"
        end

        project.on_action_finished do |a|
          action_finished << "#{a.task.name}> #{(a.output || a.name)}"
        end

        # starts all processes
        project.run("start")

        tasks = project.registry.tasks.map(&.as(Brew::Task))
        # assert pids are made and running
        tasks.each do |task|
          task.process_exists?.should eq(true)
        end

        # assert on output
        [action_start, action_succeed, action_finished].each do |output|
          output.should eq(["server-task> start server", "client-task> start client"])
          output.clear
        end
        [action_skipped, action_failed].each do |output|
          output.should be_empty
        end

        client_down = /client-task> down/
        server_down = /server-task> down/

        # restart on last process should:
        # # * stop itself
        # # * start iself
        project.run("stop", service: "client-task")
        action_finished[0]?.should match(client_down)
        action_finished.size.should eq(1)

        [action_start, action_skipped, action_failed, action_succeed, action_finished].each(&.clear)

        project.registry["client-task"].as(Brew::Task).process_exists?.should eq(false)
        project.registry["server-task"].as(Brew::Task).process_exists?.should eq(true)

        project.run("stop")
        project.registry["client-task"].as(Brew::Task).process_exists?.should eq(false)
        project.registry["server-task"].as(Brew::Task).process_exists?.should eq(false)

        action_skipped[0]?.should match(client_down)
        action_finished[0]?.should match(server_down)

        [action_start, action_skipped, action_failed, action_succeed, action_finished].each(&.clear)

        # restart on all processes should:
        # stop client-task
        # stop server-task
        # start server-task
        # start client-task
        project.run("restart")

        project.registry.tasks.each do |task|
          task.as(Brew::Task).process_exists?.should eq(true)
        end

        [client_down, server_down].each_with_index do |regex, idx|
          action_skipped[idx]?.should match(regex)
        end

        action_start.should eq(["server-task> start server", "client-task> start client"])

        [action_start, action_skipped, action_failed, action_succeed, action_finished].each(&.clear)

        # stop on just server should cascade against the inverted dependencies.
        project.run("stop", service: "server-task")

        project.registry.tasks.each do |task|
          task.as(Brew::Task).process_exists?.should eq(false)
        end

        [client_down, server_down].each_with_index do |regex, idx|
          action_finished[idx]?.should match(regex)
        end
      end
    end
  end
end
