require "../src/barista"

class Geoffrey < Barista::Project
  include Barista::Behaviors::Run::Project

  def initialize
    process_dir("./processes")
    log_dir("./log")
  end
end

# one task per process
@[Barista::BelongsTo(Geoffrey)]
class Server < Barista::Task
  include Barista::Behaviors::Run::Task

  @@name = "server"

  actions [Restart, Start, Stop, Term]

  def configure : Nil
    binary_location("ruby")
    restart_on_failure(false)
  end
end

class Start < Barista::Behaviors::Run::Action
  @@name = "start"

  # start process at locattion
  # save pid to file.
  def execute
    run("test.rb")
  end

  def skip? : Bool
    process_exists?
  end
end

class Stop < Barista::Behaviors::Run::Action
  @@name = "stop"

  def execute
    quit
  end

  def skip? : Bool
    !process_exists?
  end
end

class Term < Barista::Behaviors::Run::Action
  @@name = "term"

  def execute
    term
  end

  def skip? : Bool
    !process_exists?
  end
end

class Restart < Barista::Behaviors::Run::Action
  @@name = "restart"

  wait(false)

  def execute
    action Stop
    action Start
  end

  def skip? : Bool
    false
  end
end

Geoffrey.new.console_application.run