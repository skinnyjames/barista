module Barista
  # stores the list of tasks organized in a dependency graph
  class Registry(T)
    getter :tasks

    def initialize(@tasks = [] of T); end

    # add a task
    def <<(task)
      @tasks << task if self[task.name]?.nil?
    end

    # get a directed acyclic graph
    # from a task list
    def dag
      graph = Graph.new

      tasks.dup.each do |task|
        graph.add(task.name)

        task.dependencies.each do |dependency|
          graph.add_edge(dependency.name, task.name)
        end
      end

      graph
    end

    # get a single task
    def [](name : String) : T
      to_groups[name]
    end

    def []?(name : String) : T?
      to_groups[name]?
    end

    # get a flat list of upstream dependencies
    def upstreams(task : T) : Array(T)
      lookup = to_groups
      filtered = dag.filter([task.name])
      (filtered - [task.name]).map do |name|
        lookup[name]
      end
    end

    def upstreams(task : String) : Array(T)
      lookup = to_groups
      filtered = dag.filter([task])
      (filtered - [task]).map do |name|
        lookup[name]
      end
    end

    def reset
      @tasks = [] of T
    end

    protected def to_groups
      tasks.reduce({} of String => T) do |memo, task|
        memo[task.name] = task
        memo
      end
    end
  end
end

