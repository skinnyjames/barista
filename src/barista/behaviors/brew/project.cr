require "log"

module Barista
  module Behaviors
    module Brew
      class NoTasks < Exception; end
      struct SimpleFormat < ::Log::StaticFormatter
        def run
          message
        end
      end

      module ProjectClassMethods
        def recipe(name)
          recipe = Barista::Behaviors::Brew::Recipe.new

          with recipe yield

          @@recipes[name] = recipe
        end

        def invert(*names)
          @@inverted_commands = names.to_a
        end
      end

      module Project
        include Macros
        include FileUtils
        include Brew::Events
        
        macro included
          @@inverted_commands = [] of String
          @@recipes = {} of String => Barista::Behaviors::Brew::Recipe
          
          extend Barista::Behaviors::Brew::ProjectClassMethods
        end 

        def run(command, *, workers : Int32 = 1, service : String? = nil)
          if dir = log_dir
            mkdir_p(dir)
          end

          mkdir_p(process_dir)

          if recipe = @@recipes[command]?
            run_recipe(recipe, workers: workers)
          else
            init_tasks_with(command)
        
            orchestrator = Barista::Orchestrator.new(registry_for(command), workers: workers, filter: service.try(&.split(",")))
            orchestrator.execute
          end
        end

        def run_recipe(recipe, *, workers : Int32)
          recipe.actions.each do |command, filter|
            init_tasks_with(command)

            orchestrator = Barista::Orchestrator.new(registry_for(command), workers: workers, filter: filter)
            orchestrator.execute
          end
        end

        def init_tasks_with(command)
          registry.reset

          colors = Barista::ColorIterator.new

          tasks_to_run = tasks.map do |klass|
            logger = Barista::RichLogger.new(color: colors.next, name: klass.name)

            task = klass.new(self, command).as(Barista::Behaviors::Brew::Task)

            task.on_output do |str|
              logger.info { str }
            end
            
            task.on_error do |str|
              logger.error { str }
            end
          end

          raise NoTasks.new("No tasks to run for #{command}") unless tasks_to_run.any?(&.as(Brew::Task).runnable?)
        end

        def registry_for(command)
          @@inverted_commands.includes?(command) ? registry.invert : registry
        end

        def default_output
          Barista::Log.backend(::Log::IOBackend.new(formatter: SimpleFormat))

          on_action_skipped do |action|
            Barista::Log.warn(action.task.name) { action.output || "#{action.name} skipped (#{action.task.pid_info})" }
          end

          on_action_start do |action|
            Barista::Log.debug(action.task.name) { action.output || "#{action.name} starting (#{action.task.pid_info})" }
          end

          on_action_succeed do |action|
            Barista::Log.info(action.task.name) { action.output || "#{action.name} succeeded (#{action.task.pid_info})".colorize(:green).to_s }
          end

          on_action_failed do |action|
            Barista::Log.error(action.task.name) { action.output || "#{action.name} starting (#{action.task.pid_info})" }
          end

          on_action_finished do |action|
            Barista::Log.debug(action.task.name) { action.output || "#{action.name} finished (#{action.task.pid_info})" }
          end

          self
        end

        macro included 
          def console_application
            app = previous_def
            app.add(Barista::Behaviors::Brew::CliCommand.new(self))
            app.default_command("run", true)
            app
          end
        end

        gen_method(:log_dir, String?) { nil }
        gen_method(:process_dir, String) { missing_attribute("process_dir") }
      end
    end
  end
end
