module Brew::Fixture
  class Project < Barista::Project
    include_behavior(Brew)
    nametag("fixture-project")

    invert "stop", "kill", "stop", "gkill"

    recipe "restart" do
      action "stop"
      action "start"
    end

    def initialize
      process_dir("#{downloads_path}/brew/process")
      log_dir("#{downloads_path}/brew/log")
    end
  end

  module Server
    @[Barista::BelongsTo(::Brew::Fixture::Project)]
    class Task < Barista::Task
      include Barista::Behaviors::Brew::ProcessActions

      include_behavior(Brew)
      nametag("server-task")
      
      actions Start

      def server_port
        ENV["BREW_PORT"]? || "8083"
      end
    end

    class Start < Barista::Behaviors::Brew::Action
      nametag("start")
      def execute
        supervise("crystal run #{external_fixture("run/server.cr")}", env: { "BREW_PORT" => task.as(Server::Task).server_port })
      end

      def skip? : Bool
        process_exists?
      end

      def ready? : Bool
        http_ok?("http://localhost:#{task.as(Server::Task).server_port}")
      end

      def output
        "start server"
      end
    end
  end

  module Client
    @[Barista::BelongsTo(::Brew::Fixture::Project)]
    class Task < Barista::Task
      include Barista::Behaviors::Brew::ProcessActions

      include_behavior(Brew)
      nametag("client-task")

      dependency Server::Task
      actions Start

      def server_port
        ENV["BREW_PORT"]? || "8083"
      end
    end

    class Start < Barista::Behaviors::Brew::Action
      nametag("start")
      def execute
        supervise("crystal", ["run", "#{external_fixture("run/client.cr")}"], env: { "BREW_PORT" => task.as(Client::Task).server_port })
      end

      def skip? : Bool
        process_exists?
      end

      def ready? : Bool
        skip?
      end

      def output 
        "start client"
      end
    end
  end
end