module Barista
  module Behaviors
    module Software
      module OS
        module Darwin
          # Platform information for Darwin
          struct Platform
            getter :info

            @info : Hash(Symbol, String?) = {} of Symbol => String?

            def initialize
              init_platform_info
            end

            def name
              "mac_os_x"
            end

            def family
              "mac_os_x"
            end

            def version : String?
              info[:os_platform_version]?
            end

            def build_version : String?
              info[:os_build_version]?
            end

            private def init_platform_info
              so = `/usr/bin/sw_vers`
              so.split("\n").each do |line|
                case line
                when /^ProductVersion:\s+(.+)$/
                  @info[:os_platform_version] = $1
                when /^BuildVersion:\s+(.+)$/
                  @info[:os_build_version] = $1
                end
              end
            end
          end
        end
      end
    end
  end
end
