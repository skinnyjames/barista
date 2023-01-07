# Representing tasks in a Directed Acyclic Graph (DAG)

In order to know which tasks are ready to built at a given point in time, Barista stores them in a dependency graph.

[Barista::Graph][] stores a DAG of simple strings, which are stored and converted to tasks by `Barista::Registry`

For the most part, there is no need to interact directly with the registry, but it may come into play when writing new Behaviors.

```crystal
class TaskOne < Barista::Task
  def execute : Nil; end
end

class TaskTwo < Barista::Task
  dependency TaskOne
  
  def execute : Nil; end
end

# the Registry is generic, so we need to specify the type it contains.
registry = Barista::Registry(Barista::Task).new

registry << TaskOne.new
registry << TaskTwo.new
```

We can retrive objects from the registry with [Barista::Registry#[]][] or we can get all of the upstreams for a task with [Barista::Registry#upstreams][]

```crystal
registry.upstreams("TaskTwo") # => ["TaskOne"]
```

