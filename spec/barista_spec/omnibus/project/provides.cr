module Internal
  class Provides < Barista::Project
    include Barista::Behaviors::Omnibus::Project

    @@name = "provides-project"

    def initialize
      install_dir("#{downloads_path}/internal/install")
      barista_dir("#{downloads_path}/internal/barista")
      maintainer("GitLab Quality <quality@gitlab.com>")
      homepage("https://gitlab.com/gitlab-org/quality/barista-gitlab-builder")
      license("Apache-2.0")
      build_version("1")
    end

    def build(provider : BaristaSpec::Omnibus::Provider)
      tasks.each do |klass|
        task = klass.new(self).as(Barista::Behaviors::Omnibus::Task)
        task.on_output { |str| puts "#{task.name} > #{str}" }
        task.on_error { |str| puts "#{task.name} > #{str}" }
      end

      orchestration = orchestrator(workers: 5)

      orchestration.on_run_start do
        provider.prepare
      end

      orchestration.on_task_start do |name|
        task = registry[name].as(Barista::Behaviors::Omnibus::Task)

        provider.prepare(task)
      end

      orchestration.execute
    end
  end

  @[Barista::BelongsTo(Internal::Provides)]
  class TaskInstallsBinary < Barista::Task
    include Barista::Behaviors::Omnibus::Task

    @@name = "task-installs-binary"

    def build : Nil
      env = with_embedded_path(with_standard_compiler_flags(with_destdir))

      command("./configure", env: env)
      command("make foo bar", env: env)
    end

    def configure : Nil
      version("1.0.0")
      license("MIT")
      license_file("COPYING")
      source("http://www.example.com/install-binary.tar.gz")
    end
  end

  @[Barista::BelongsTo(Internal::Provides)]
  class TaskProvidesLicense < Barista::Task
    include Barista::Behaviors::Omnibus::Task

    @@name = "task-provides-license"

    def build : Nil
      emit("noop")
    end

    def configure : Nil
      version("1.0.0")
      license("MIT")
      license_file("LICENSE")
      source("http://www.example.com/provide-license.tar.gz")
    end
  end

  @[Barista::BelongsTo(Internal::Provides)]
  class TaskNeedsBinary < Barista::Task
    include Barista::Behaviors::Omnibus::Task

    dependency TaskInstallsBinary

    @@name = "task-needs-binary"

    def build : Nil
      bin("task-installs-binary", "foo bar")
    end

    def configure : Nil
      version("1.0.0")
      license("MIT")
    end
  end
end
