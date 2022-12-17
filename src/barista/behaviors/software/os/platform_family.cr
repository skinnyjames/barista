module Barista
  module Behaviors
    module Software
      module OS
        module PlatformFamily
          def platform_short_name
            if rhel?
              "el"
            elsif suse?
              "sles"
            else
              platform.family
            end
          end

          def arch?
            platform.family == "arch"
          end

          def aix?
            platform.family == "aix"
          end

          def debian?
            platform.family == "debian"
          end

          def fedora?
            platform.family == "fedora"
          end

          def macos?
            platform.family == "mac_os_x"
          end

          def rhel?
            platform.family == "rhel"
          end

          def rhel6?
            rhel? && rhelv?(6.0, 7.0)
          end

          def rhel7?
            rhel? && rhelv?(7.0, 8.0)
          end

          def rhel8?
            rhel? && rhelv?(8.0, 9.0)
          end

          def amazon?
            platform.family == "amazon"
          end

          def solaris?
            platform.family == "solaris2"
          end

          def smartos?
            platform.family == "smartos"
          end

          def suse?
            platform.family == "suse"
          end

          def gentoo?
            platform.family == "gentoo"
          end

          def freebsd?
            platform.family == "freebsd"
          end

          def openbsd?
            platform.family == "openbsd"
          end

          def netbsd?
            platform.family == "netbsd"
          end

          def rpm_based?
            redhat_based? || amazon?
          end

          def redhat_based?
            fedora? || redhat?
          end

          private def rhelv?(min : Float32, max : Float32)
            rhel? && begin
              v = platform.version.try(&.to_f) || 0
              v > min && v < max
            end
          end
        end
      end
    end
  end
end
