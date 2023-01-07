
module Barista
  annotation BelongsTo; end
  module TaskInstanceMethods
    def sequences : Array(String)
      @@sequences
    end

    def dependencies
      @@dependencies
    end

    def name : String 
      @@name || {{ @type.id.stringify }}
    end
  end

  # An extension to use with a Barista::Task
  # 
  # Not meant for external use, but here for doc generation.
  module TaskClassMethods
    # Declare a dependency on another task. 
    # When orchestrating, this task will always run after any dependencies.
    def dependency(task : Barista::Task.class)
      @@dependencies << task
    end

    def sequence(groups : Array(String))
      @@sequences = groups
    end

    def dependencies
      @@dependencies
    end

    def belongs_to : Array(Barista::Project.class)
      arr = [] of Barista::Project.class

      {% for ann, idx in @type.annotations(Barista::BelongsTo) %}
        arr << {{ ann[0] }}
      {% end %}

      arr
    end

    def name : String 
      @@name || {{ @type.id.stringify }}
    end
  end

  abstract class Task
    abstract def execute

    def initialize()
      {% for ann, idx in @type.annotations(::Barista::BelongsTo) %}
        {{ ann[0] }}.registry << self
      {% end %}

      self
    end

    macro inherited
      @@name : String?
      @@dependencies = [] of Barista::Task.class
      @@sequences = [] of String

      {% for ann, idx in @type.annotations(Barista::BelongsTo) %}
        extend Barista::Projectable({{ ann[0] }})
        {{ ann[0] }}.tasks << self
      {% end %}

      include Barista::TaskInstanceMethods
      extend Barista::TaskClassMethods
    end
  end
end