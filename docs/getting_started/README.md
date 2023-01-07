# Getting Started

## Writing a Project

While not mandatory, the easiest way to encapsulate a collection of tasks is to write a class that implements [Barista::Project][].

A Project provides some helpful abstractions to collect tasks in a [Barista::Registry][] automatically, which can return a Directed Acyclic Graph.

Note: _Certain Behavior mixins will also provide additional functionality for a project._

```crystal
class SanityProject < Barista::Project
  @@name = "sanity-project"
end
```

## Writing your first task

A task in Barista is simply a task that implements the [Barista::Task][] interface.

The interface expects the task class to have an `#execute` method.

```crystal
class SayHello < Barista::Task
  def execute : Nil
    puts "Hello, world."
  end
end

SayHello.new.execute # => Hello, World
```

This isn't all that useful on it's own, but we can orchestrate the timing of how and when tasks execute by using an Orchestrator and declaring dependencies: [Barista::TaskClassMethods#dependency][]

### Barista::BelongsTo

Barista provides an [Annotation](https://crystal-lang.org/reference/1.6/syntax_and_semantics/annotations/index.html) to associate a task with Projects.

We can use it like this:

```crystal
# This annotation will add the Task class to SanityProject's task list.
# When the class is instantiated, the new object will be added to SanityProject's registry
@[Barista::BelongsTo(SanityProject)]
class SayHello < Barista::Task
  def execute : Nil
    puts "Hello, world."
  end
end
```
This is the only real piece of magic, but it's helpful for not having to manually add each object
to a project's registry, and allows us to instantiate tasks with our own state.

```crystal
task = SayHello.new
project = SanityProject.new
orchestrator = Barista::Orchestrator(Barista::Task).new(project.registry)

orchestrator.execute # => Hello, world.
```
Note: _A task can belong to multiple projects by adding more @[Barista::BelongsTo()] annotations_

## Putting it all together

With a rudimentary task runner, lets define a set of tasks that are orchestrated concurrently.

```crystal
class Coffeeshop < Barista::Project
  @@name = "coffeeshop"

  def execute(workers : Int32)
    # instantiate the tasks so they get added to the registry
    tasks.each(&.new)

    Barista::Orchestrator(Barista::Task).new(registry, workers: workers).execute
  end
end

@[Barista::BelongsTo(Coffeeshop)]
class GrindCoffeeBeans < Barista::Task
  def execute : Nil
    puts "Grinding coffee beans..."
    sleep 1
    puts "Coffee beans are ready"
  end
end

@[Barista::BelongsTo(Coffeshop)]
class SteamMilk < Barista::Task
  def execute : Nil
    puts "Steaming the Milk..."
    sleep 2
    puts "Milk is ready"
  end
end

@[Barista::BelongsTo(Coffeeshop)]
class BrewCoffee < Barista::Task
  dependency GrindCoffeeBeans

  def execute : Nil
    puts "Percolating Coffee..."
  end
end

@[Barista::BelongsTo(Coffeeshop)]
class ServeCoffe < Barista::Task
  dependency BrewCoffee
  dependency SteamMilk

  def execute : Nil
    puts "Serving the coffee. Have a good day!"
  end
end

# Run the tasks against 4 concurrent workers.
Coffeeshop.new.execute(workers: 4)
```

This program will start the tasks in the following order:

1. `GrindCoffeeBeans` and `SteamMilk` will start at the same time.
2. When `GrindCoffeeBeans` is done, `BrewCoffee` will start.
3. When `BrewCoffee` and `SteamMilk` are done, `ServeCoffee` will run.

Producing this output:

```
Grinding coffee beans...
Steaming the Milk...
Coffee beans are ready
Percolating Coffee...
Milk is ready
Serving the coffee. Have a good day!
```