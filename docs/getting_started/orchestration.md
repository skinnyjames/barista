# Orchestration

The primary use case for Barista is to orchestrate work concurrently.  
Barista capitalizes on Crystal's syntax and concurrency mechanisms to accomplish this.

The main entrypoint for this is [Barista::Orchestrator][], (but you can write your own).

## Serial tasks

An way to prevent concurreny among a group of tasks is using [Barista::TaskClassMethods#sequence][]

The `sequence` class method takes an array of strings.  
As that task is executing, if any of the same sequences are encountered in other tasks during a concurrent build, `Barista::Orchestrator` will 
block those tasks one-by-one until each task is complete.

Any tasks that do not share the same sequences or have no sequences will continue to execute concurrently.

For instance, perhaps some tasks all mutate the same state, which might cause race conditions.  We can avoid this as demonstrated below.

!!! note
    although named sequence, this mechanism offers no guarantees on the `order` that each task is executed.  If order is important, use `dependency`

```crystal
class TaskOne < Barista::Task
  sequence ["mutates-shared-state"]
  
  def execute : Nil
    File.open("/some/shared/state", "w") do |file|
      file.puts "This comes from TaskOne"
    end
  end
end

class TaskTwo < Barista::Task
  sequence ["mutates-shared-state"]

  def execute : Nil
    File.open("/some/shared/state", "w") do |file|
      file.puts "This comes from TaskTwo"
    end
  end
end

class NonSequencedTask < Barista::Task
  def execute : Nil
    puts "No sequences here!"
  end
end
```

Even though `TaskOne` and `TaskTwo` are independent, only one will run at a time.  `NonSequencedTask` will continue to run concurrently to the serial group.

## Orchestration Events

As [Barista::Orchestrator][] executes the graph of dependencies, it will emit events.

The list of events can be found in [Barista::OrchestrationEvents][].

We can subscribe to events as follows.

```crystal
orchestrator = Barista::Orchestrator(Barista::Task).new(some_registry)

orchestrator.on_run_start do
  puts "Starting to execute the tasks"
end

orchestrator.on_run_finsihed do
  puts "The tasks are all finished!"
end

orchestrator.on_unblocked do |orchestration_info|
  puts "Lifecycle Information: #{orchestration_info.to_s}"
end

orchestrator.on_task_start do |task|
  puts "Task #{task} is starting"
end

orchestrator.on_task_failed do |task, exception_string|
  puts "Task #{task} failed with exception: #{exception_string}"
end

orchestrator.on_task_succeed do |task|
  puts "Task #{task} succeeed"
end

orchestrator.on_task_finished do |task|
  puts "Task succeeded or failed"
end

orchestrator.execute
```