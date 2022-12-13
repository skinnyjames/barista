require "../../src/barista"
require "./coffee_shop/**"

class Coffeeshop < Barista::Project
  include Barista::Behaviors::Omnibus::Project

  getter :workers

  def install_dir
    "/opt/coffeeshop"
  end
  
  def barista_dir
    "/opt/barista"
  end

  def dry_run
    tasks.each(&.new(self))
  end 

  def build(@workers : Int32 = 4, filter : Array(String)? = nil)  : Nil
    colors = Barista::ColorIterator.new
  
    tasks.each do |task_klass|
      logger = Barista::RichLogger.new(colors.next, task_klass.name)

      task = task_klass.new(self)

      task.on_output do |str|
        logger.info { str }
      end

      task.on_error do |str|
        logger.error { str }
      end
    end

    orchestrator = Barista::Orchestrator(Barista::Task).new(registry, workers: workers, filter: filter)
    
    orchestrator.on_task_start do |task|
      Barista::Log.info(task) { "starting build" }
    end

    orchestrator.on_task_failed do |task, ex|
      Barista::Log.error(task) { "build failed: #{ex}" }
    end

    orchestrator.on_task_succeed do |task|
      Barista::Log.info(task) { "build succeeded" }
    end

    orchestrator.on_unblocked do |tasks|
      Barista::Log.info("Coffeeshop") { "Tasks unblocked: #{tasks.join(", ")}" }
    end

    orchestrator.execute
  end

  def console_application
    app = previous_def
    app.add(Build.new(self))
    app
  end

  def configure
    install_dir("/opt/coffeeshop")
    barista_dir("/opt/barista")
  end
end

Coffeeshop.new.console_application.run