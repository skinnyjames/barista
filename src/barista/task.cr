module Barista
  abstract class Task(T)
    abstract def execute

    macro inherited
      T.register(self)

      @@name : String?
      @@dependencies = [] of Barista::Task(T).class

      def self.dependency(task : Barista::Task(T).class)
        @@dependencies << task
      end

      def self.dependencies
        @@dependencies
      end

      def dependencies
        @@dependencies
      end

      def self.name : String 
        @@name || {{ @type.id.stringify }}
      end

      def name : String 
        @@name || {{ @type.id.stringify }}
      end
    end
  end
end