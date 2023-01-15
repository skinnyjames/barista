# Brew

The Brew behavior is a basic set of interfaces for writing idempotent actions that bring a system or subcomponent to a desired state.

It primary use case is persistent process supervsion, although it can be used for short-lived actions as well.

It exposes a CLI that can be compiled to run commands that concurrently orchestrate actions.

Each task represents a single resource that belongs to a project.

An interface is provided to write classes that represent a idempotent action against a resource.  
These actions can be provided to a task via [Barista::Behaviors::Brew::TaskClassMethods#actions(*)][]


## Project

Like other Barista Behaviors, a Project is used for orchestrating a collection of tasks.

A [Barista::Behaviors::Brew::Project][] is bootstrapped with a CLI designed for orchestrating a single action against a graph per invocation.

It exposes methods for specifying 

* which commands use an inverted dependency graph (used for [reversing](#reversible-actions) a change to a system)
* recipes that can perform a set of actions in a single command
* configuration of where process pids and process logs should live

## Task

A Brew task is for representing a singular resource which can alternate between different desired states.

Tasks can have dependencies on other tasks, and commands will attempt to cascade across all tasks.
They also manage process supervision handling should an action use it.

!!! info

     If a task depends on another task, executing an action will attempt to execute the same action on it's upstreams *first*

     This is desireable to ensure the proper state for the target task to run.

     _This behavior can also be [inverted](#reversible-actions)_

## Actions

An `Action` represents an idempotent operation in the context of a task.

To create one, we can implement [Barista::Behaviors::Brew::Action][]

The interface specifies that we need 2 methods 

* `action#skip?` returns a boolean indicating whether or not this operation should be skipped.
* `action#ready?` returns a boolean indiciation if this action is fully complete

!!! note
    
    `action#ready?` will be run inside of a wait condition that rescues errors until the method returns `true` or the wait condition times out.


and since this is a [Barista::Task][] it also requires an `execute` method.  `#execute` is invoked to perform the action.


### Reversible Actions

Since tasks can depend on each other, upstreams dependencies will be executed **first**.
This is great to get to a desired state, but what about reversing the desired state?

The `#invert` method on a project specifies which commands should use an inverted dependency graph.

* When installing a collection of software, we want to install any upstreams first.
* When uninstalling a collection of software, it usually makes sense to uninstall the downstreams firat.

## Install/Uninstall Example

For an example of a Brew project, we can consider installing and uninstalling asdf.
In this example, asdf depends on homebrew.  

* When running the `install` command, postgres will be installed first, and then asdf
* When running the `uninstall` command, asdf will be removed first and then postgres

```crystal
require "./src/barista"

class SoftwareProject < Barista::Project
  include_behavior(Brew)

  invert("uninstall")

  recipe("reinstall") do
    action("uninstall")
    action("install")
  end

  def initialize
    process_dir("./me/process")
    log_dir("./me/log")
  end
end

module Homebrew 
  @[Barista::BelongsTo(SoftwareProject)]
  class Task < Barista::Task
    include_behavior(Brew)

    @@name = "homebrew"

    actions(Install, Uninstall)
  end

  class Install < Barista::Behaviors::Brew::Action
    @@name = "install"

    def skip? : Bool
      success?("which brew")
    end

    def ready? : Bool
      skip?
    end

    def execute
      command("/bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"", env: { "NONINTERACTIVE" => "1" })
      patch_bash_profile_if_needed
    end

    def patch_bash_profile_if_needed
      user = run("whoami").output
      profile = run("cat /home/#{user}/.bash_profile").output

      return if profile.includes?("Homebrew")

      run("echo '# Set PATH, MANPATH, etc., for Homebrew.' >> /home/#{user}/.bash_profile")
      run("echo 'eval \"$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)\"' >> /home/#{user}/.bash_profile")
      run("eval \"$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)\"")
    end
  end

  class Uninstall < Barista::Behaviors::Brew::Action
    @@name = "uninstall"

    def skip? : Bool
      !success?("which brew")
    end

    def ready? : Bool
      skip?
    end

    def execute
      command("/bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)\"", env: { "NONINTERACTIVE" => "1" })
    end
  end
end

module Asdf
  @[Barista::BelongsTo(SoftwareProject)]
  class Task < Barista::Task
    include_behavior(Brew)

    dependency Homebrew::Task

    @@name = "asdf"

    actions(Install, Uninstall)
  end

  class Install < Barista::Behaviors::Brew::Action
    @@name = "install"

    def skip? : Bool
      success?("brew list asdf")
    end

    def ready? : Bool
      skip?
    end

    def execute
      command("brew install asdf")
    end
  end

  class Uninstall < Barista::Behaviors::Brew::Action
    @@name = "uninstall"

    def skip? : Bool
      !success?("brew list asdf")
    end

    def ready? : Bool
      skip?
    end

    def execute
      command("brew uninstall --force asdf")
      command("brew autoremove")
    end
  end
end

SoftwareProject
  .new
  .default_output
  .console_application
  .run
```

