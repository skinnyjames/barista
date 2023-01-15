# Supervision

The Brew behavior also implicitly supports process supervision as part of executing tasks.

If an action execution for a task returns a [Brew::SupervisorCommand](barista/Barista/Behaviors/Brew/SupervisorCommand/), then that process will be monitored.
The entrypoint to do this is [Barista::Behaviors::Brew::Action#supervise][]
!!! warning

    It's important to only supervise one process per task.

    Trying to supervise different processes from a single task will lead to orphaned processes.

!!! note

    Supervision works by forking a new process, setting the group id to the new pid, and executing the command.

    Since any children of the new process are isolated by the group, Brew actions can send a signal to terminate the group.

## Example Project

One use case could be running a web application against a database.

Both of these services are long running processes that can be supervised with Brew.

```crystal
class MyCoolApplication < Barista::Project
  include_behavior(Brew)
  nametag("my-cool-application")

  def initialize
    process_dir("./run/process")
    log_dir("./run/log")
  end
end

MyCoolApplication
  .new
  .default_output
  .console_application
  .run
```

This script compiles to a binary that bootstraps a process supervisor.

Long running pids will be written to `./run/process/<task>.pid` and logs to `./run/log/<task>.log`

We can add tasks to this project using the [Barista::BelongsTo][] annotation.

### Tasks

Since this example application controls two processes (a database and webserver), we will need two tasks.

```crystal
module Postgres
  @[Barista::BelongsTo(MyCoolApplication)]
  class Task < Barista::Task
    include_behavior(Brew)

    nametag("postgres")
    
    actions Start
  end
end

module Sinatra
  @[Barista::BelongsTo(MyCoolApplication)]
  class Task < Barista::Task
    include_behavior(Brew)

    nametag("sinatra")

    dependency Postgres::Task

    actions Start
  end
end
```

This snippet declares 2 tasks that that will produce *one* long running proccess each.

_(Note that `Sinatra::Task` depends on `Postgres::Task`)_

it also uses the `actions` class method to describe any actions for these tasks. 

!!! info

    The Brew behavior ships with a mixin to add actions that help manage the process.

    These can be added automatically by including `Barista::Behaviors::Brew::ProcessActions` into the target task class.

    * "status" outputs the status of the process
    * "stop" sends a `TERM` signal to the process
    * "kill" sends a `KILL` signal to the process

### Actions

Actions also come with methods that provide information about the process of a task if it has one.

* `process_exists?` returns a boolean indicating the a process for the task exists and is active
* `supervise` returns a [Brew::SupervisorCommand](barista/Barista/Behaviors/Brew/SupervisorCommand/) that will cause the task to capture the command pid to a file.


```crystal
module Postgres
  class Start < Barista::Behaviors::Brew::Action
    nametag("start")

    def skip? : Bool
      process_exists?
    end

    def ready? : Bool
      process_exists?
    end

    def execute
      supervise("/location/to/postgres -D /some/data/dir")
    end
  end
end

module Sinatra
  class Start < Barista::Behaviors::Brew::Action
    nametag("start")

    def skip? : Bool
      process_exists?
    end

    def ready? : Bool
      http_ok?("http://localhost:8080/healthcheck")
    end

    def execute
      supervise("ruby /path/to/app.rb")
    end
  end
end
```

!!! warning

    If using the supervision behavior, remember to [invert](../#reversible-actions) any commands that take the process down.

    This includes the `stop` and `kill` commands shipped with `Barista::Behaviors::Brew::ProcessActions`