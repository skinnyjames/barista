
annotation Project; end
module Barista
  abstract class Task
    abstract def execute

    def initialize()
      {% for ann, idx in @type.annotations(::Project) %}
        {{ ann[0] }}.registry << self
      {% end %}

      self
    end

    macro inherited
      @@name : String?
      @@dependencies = [] of Barista::Task.class

      {% for ann, idx in @type.annotations(Project) %}
        extend Barista::Projectable({{ ann[0] }})
        {{ ann[0] }}.tasks << self
      {% end %}

      def self.dependency(task : Barista::Task.class)
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

      def self.belongs_to : Array(Barista::Project.class)
        arr = [] of Barista::Project.class

        {% for ann, idx in @type.annotations(Project) %}
          arr << {{ ann[0] }}
        {% end %}

        arr
      end
    end
  end
end