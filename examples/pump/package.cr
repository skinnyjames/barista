module Resource
  class Package(T)
    @filter = [] of String
    @packager : Barista::Project

    def initialize(@name : String, &block)
      @packager = T.new(@name)
      with @packager yield
    end

    def execute
      @packager.execute(@filter)
    end

    def action(filter : Array(String))
      @filter = filter
    end
  end
end

module Debian
  class Package < Barista::Pump::Resource
    def initialize(name : String)
      tasks.each do |klass|
        klass.new(name)
      end
    end

    def execute(actions : Array(String) = ["install"]) : Nil
      orchestrator(workers : 1, filter: actions)
    end
  end

  @[Barista::BelongsTo(Debian::Package)]
  class Install < Barista::Pump::Action
    @@name = "install"

    def check : Bool
    end
    
    def build : Nil
      
    end
  end

  @[Barista::BelongsTo(Debian::Package)]
  class Uninstall < Barista::Pump::Action
    @@name = "uninstall"

    def check : Bool
    end

    def build : Bool
    end
  end
end

macro package(name, &block)
  case platform.family
  when "debian", "ubuntu", "fedora"
    Resource::Package(Debian::Package).new({{name}}) {{ block }}
  end
end

class PumpProject < Barista::Project
end