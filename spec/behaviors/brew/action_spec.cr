require "../../spec_helper"

private class ActionProject < Barista::Project
  include_behavior(Brew)

  def initialize
    log_dir("#{downloads_path}/log")
    process_dir("#{downloads_path}/process")
  end
end

@[Barista::BelongsTo(ActionProject)]
private class ActionTask < Barista::Task
  include_behavior(Brew)
  nametag("action")
  actions(UserPerm)
end

private class UserPerm < Barista::Behaviors::Brew::Action
  nametag("userperm")

  def skip? : Bool
    false
  end

  def ready? : Bool
    true
  end

  def execute
    if username = barista_test_user
      setup_dir(username)

      run("echo 'hello' > #{downloads_path}/#{username}/hello", as_user: username)
      as_user(username) do
        File.write("#{downloads_path}/#{username}/foo", "foo")
      end
      File.write("#{downloads_path}/#{username}/bar", "bar")
    end
  end

  private def setup_dir(username)
    mkdir("#{downloads_path}/#{username}")
    run("chmod -Rf 755 #{downloads_path}/#{username}")
    run("chown #{username} #{downloads_path}/#{username}")
  end
end

module Barista::Behaviors::Brew
  describe "Action" do
    if barista_test_user && `whoami`.strip != barista_test_user
      it "executes command in the context of a user" do
        project = ActionProject.new
        if test_username = barista_test_user
          test_user = System::User.find_by(name: test_username)
          project.default_output.run("userperm")

          info = File.info("#{downloads_path}/#{test_username}/foo")
          info.owner_id.should eq(test_user.id)

          hello_info = File.info("#{downloads_path}/#{test_username}/hello")
          hello_info.owner_id.should eq(test_user.id)

          other = File.info("#{downloads_path}/#{test_username}/bar")
          other.owner_id.should eq(ProcessHelper.get_euid.to_s)
        end
      end
    else
      pending "Action specs: set $BARISTA_TEST_USER to unprivileged username to run this spec"
    end
  end
end