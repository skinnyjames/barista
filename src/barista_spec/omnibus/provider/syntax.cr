module BaristaSpec
  module Omnibus
    module Syntax
      class File
        include YAML::Serializable

        property name : String
        property content : String?
      end

      class Binary < File
        DEFAULT_SHELL_SCRIPT = <<-EOH
        #!/bin/sh
        
        echo "intercepting command $(basename $0) $*"
        EOH

        def content
          @content || DEFAULT_SHELL_SCRIPT
        end
      end

      abstract class Mock
        include YAML::Serializable

        use_yaml_discriminator "type", { api: ApiMock, file: FileMock }
      end

      class FileMock < Mock
        property name : String
        property content : String
      end

      class ApiMock < Mock
        property url : String
        property content : String
      end

      struct Provides
        include YAML::Serializable

        property binaries : Array(Binary)?
        property files : Array(File)?
      end

      struct Installs
        include YAML::Serializable

        property binaries : Array(Binary)?
        property files : Array(File)?
      end

      struct Task
        include YAML::Serializable

        property name : String
        property provides : Provides?
        property installs : Installs?
        property mocks : Array(Mock)?
      end

      struct System
        include YAML::Serializable

        DEFAULT_ALLOWS = ["tar", "cp", "sh", "basename", "gzip"]

        property binaries : Array(Binary)?
        property allows : Array(String)?
      end

      struct Provider
        include YAML::Serializable

        property system : System?
        property tasks : Array(Task)?

        def get_task(name : String)
          tasks.try do |tasks|
            tasks.find(&.name.==(name))
          end
        end
      end 
    end
  end
end
