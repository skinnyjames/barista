require "./packagers/*"

module Barista
  module Behaviors
    module Omnibus
      struct PackageInformation
        include Software::OS::Information
      end

      class Packager
        @@info = PackageInformation.new

        def self.platform
          @@info.platform
        end

        def self.supported?
         %w[debian ubuntu centos redhat fedora mac_os_x].includes?(platform.family) && package_klass.supported?
        end

        def self.package_klass
          case platform.family
          when "debian", "ubuntu"
            Packagers::Deb
          when "centos", "redhat", "fedora"
            Packagers::Rpm
          when "mac_os_x"
            Packagers::Pkg
          else
            raise "Can't find packager for #{platform.family}"
          end
        end

        def self.discover(project : Barista::Behaviors::Omnibus::Project)
          package_klass.new(project)
        end
      end
    end
  end
end
