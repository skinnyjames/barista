module Barista
  module Behaviors
    module Software
      module OS
        module Linux
          # Platform info for Linux
          # Borrowed from https://github.com/chef/ohai/blob/main/lib/ohai/plugins/linux/platform.rb
          # exposes #name, #family, #version
          struct Platform
            getter :info

            @info : Hash(String, String) = {} of String => String

            def initialize
              @info = init_info
            end

            def name
              platform_id_remap(platform_id)
            end

            def family
              platform_family_from_platform(name)
            end

            def version
              determine_os_version
            end

            protected def determine_os_version
              if platform_id == "centos"
                get_redhatish_version
              elsif platform_id == "debian"
                info["VERSION_ID"]? || File.read("/etc/debian_version").chomp
              else
                info["VERSION_ID"]? || `/bin/uname -r`.strip
              end
            end

            protected def get_redhatish_version
              contents = File.read("/etc/redhat-release").chomp
              contents[/(release)? ([\d\.]+)/, 2]
            end

            protected def platform_id_remap(id : String?)
              return "nexus_centos" if id == "centos" && os_release_file_is_cisco?
              id.try do |id|
                {
                  "alinux" => "alibabalinux",
                  "amzn" => "amazon",
                  "archarm" => "arch",
                  "cumulus-linux" => "cumulus",
                  "ol" => "oracle",
                  "opensuse-leap" => "opensuseleap",
                  "rhel" => "redhat",
                  "sles_sap" => "suse",
                  "sles" => "suse",
                  "xenenterprise" => "xenserver",
                }[id.downcase]? || id.downcase
              end
            end

            # detect platform family
            #
            # pulled from https://github.com/chef/ohai/blob/main/lib/ohai/plugins/linux/platform.rb
            protected def platform_family_from_platform(plat)
              case plat
              when /ubuntu/, /debian/, /linuxmint/, /raspbian/, /cumulus/, /kali/, /pop/
              # apt-get+dpkg almost certainly goes here
                "debian"
              when /centos/, /redhat/, /oracle/, /almalinux/, /rocky/, /scientific/, /enterpriseenterprise/, /xenserver/, /xcp-ng/, /cloudlinux/, /alibabalinux/, /sangoma/, /clearos/, /parallels/, /ibm_powerkvm/, /nexus_centos/, /bigip/, /virtuozzo/
                "rhel"
              when /amazon/
                "amazon"
              when /suse/, /sle[sd\-_]/
                "suse"
              when /fedora/, /arista_eos/
                "fedora"
              when /nexus/, /ios_xr/
                "wrlinux"
              when /gentoo/
                "gentoo"
              when /arch/, /manjaro/
                "arch"
              when /exherbo/
                "exherbo"
              when /alpine/
                "alpine"
              when /clearlinux/
                "clearlinux"
              when /mangeia/
                "mandriva"
              when /slackware/
                "slackware"
              end
            end

            protected def os_release_file_is_cisco?
            !!info.try { |i| i["CISCO_RELEASE_INFO"]? }
            end

            protected def platform_id
              info.try { |f| f["ID"]? }
            end

            protected def init_info : Hash(String, String)
              info = read_os_release_file("/etc/os-release")

              raise NotImplementedError.new("Can't determine platform info") if info.nil?

              info
            end

            protected def read_os_release_file(file) : Hash(String, String)?
              return nil unless File.exists?(file)

              File.read(file).split.reduce({} of String => String) do |map, line|
                if line
                  stuff = line.split("=")
                  key = stuff[0]?
                  value = stuff[1]?
                  if key && value
                      map[key] = value.gsub(/\A"|"\Z/, "") if value
                  end
                end
                map
              end
            end
          end
        end
      end
    end
  end
end
