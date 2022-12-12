require "athena-console"
require "./cli/**"
require "./registry"

module Barista
  class Project
    macro inherited
      @application : ACON::Application?
      @@registry = Barista::Registry(Barista::Task({{ @type.id }}).class).new

      def self.register(task)
        @@registry << task
      end

      def self.registry
        @@registry
      end

      def registry
        @@registry
      end

      def console_application : ACON::Application
        @application ||= begin 
          app = ACON::Application.new({{ @type.id.stringify }})
          app.add(Barista::CLI::Commands::Upstreams({{ @type.id }}).new(@@registry))
          app
        end
      end
    end
  end
end
