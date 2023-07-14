# Behaviors

[Behaviors](/barista/Barista/Behaviors) are mixins that provide additional functionality to tasks and projects in the form of state and methods.

```crystal
class SayHello < Barista::Task
  # mixin to add methods for interacting with the host / software
  include Barista::Behaviors::Software::Task

  # emits an event that contains the host OS platform family.
  def build : Nil
    emit("Hello, #{platform.family}")
  end
end

task = SayHello.new

task.on_output do |str|
  File.write("some_file", str)
end

task.execute
```

`cat some_file # => Hello, ubuntu`

## Shorthand

Generally behaviors should expose a Task and Project mixin. 

A macro is provided as short hand for mixing in behaviors

```crystal
class SayHello < Barista::Task
  # mixin to add methods for interacting with the host / software
  include_behavior(Software)

  # emits an event that contains the host OS platform family.
  def build : Nil
    emit("Hello, #{platform.family}")
  end
end
```

There are currently 3 behaviors bundled with Barista

* [Barista::Behaviors::Software](/barista/behaviors/software)
* [Barista::Behaviors::Omnibus](/barista/behaviors/omnibus)
* [Barista::Behaviors::Brew](/barista/behaviors/brew)
