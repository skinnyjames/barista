require "athena-console"
require "./cli/**"
require "./registry"

module Barista
  module Projectable(T); end
  abstract class Project
    macro inherited
      @application : ACON::Application?
      @@tasks = [] of Barista::Projectable({{ @type.id }})
      @@registry = Barista::Registry(Barista::Task).new

      def self.<<(task)
        @@tasks << task
      end
      
      def self.registry
        @@registry
      end

      def registry
        @@registry
      end

      def self.tasks : Array(Barista::Projectable({{ @type.id }}))
        @@tasks
      end

      def tasks
        self.class.tasks
      end

      def console_application : ACON::Application
        @application ||= begin 
          app = ACON::Application.new({{ @type.id.stringify }})
          app.add(Barista::CLI::Commands::Upstreams({{ @type.id }}).new)
          app
        end
      end
    end
  end
end
