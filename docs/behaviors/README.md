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

There are currently 2 behaviors bundled with Barista, [Barista::Behaviors::Software][] and [Barista::Behaviors::Omnibus][].
