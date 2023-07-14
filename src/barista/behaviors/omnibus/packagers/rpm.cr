module Barista
  module Behaviors
    module Omnibus
      module Packagers
        class Rpm < Base
          gen_supported("which rpmbuild", /no rpmbuild/)

          def supported? : Bool
            Rpm.supported?
          end

          SPEC_TEMPLATE = Barista.project_file("/behaviors/omnibus/packagers/scripts/rpm/spec.hbs")
          SIGNING_TEMPLATE = Barista.project_file("/behaviors/omnibus/packagers/scripts/rpm/signing.hbs")
          FILESYSTEM_LIST = Barista.project_file("/behaviors/omnibus/packagers/scripts/rpm/filesystem_list")

          SCRIPT_MAP = {
            # Default Omnibus naming
            :preinst => "pre",
            :postinst => "post",
            :prerm => "preun",
            :postrm => "postun",
            # Default RPM naming
            :pre => "pre",
            :post => "post",
            :preun => "preun",
            :postun => "postun",
            :verifyscript => "verifyscript",
            :pretrans => "pretrans",
            :posttrans => "posttrans",
          }

          delegate(:license, to: @project)

          def initialize(@project : Barista::Behaviors::Omnibus::Project); end
          
          def id : Symbol
            :rpm
          end

          gen_method(:compression_level, Int32) { 9 }
          gen_method(:compression_type, Symbol) { :gzip }
          gen_method(:category, String) { "default" }
          gen_method(:priority, String) { "extra" }
          gen_method(:license, String) { project.license }
          gen_method(:vendor, String) { "Barista <sean.christopher.gregory@gmail.com>" }
          gen_method(:signing_passphrase, String?) { nil }
          gen_method(:dist_tag, String) { ".#{platform_short_name}#{platform.version}" }

          def configure : Nil
            %w[BUILD RPMS SRPMS SOURCES SPECS].each do |dir|
              task_mkdir(File.join(prepare_dir, dir), parents: true)
            end

            destination = File.join(build_dir, project.install_dir)
            Software::Merger.new(project.install_dir, destination, exclude: exclusions, includes: inclusions).execute


            project.extra_package_files.each do |file|
              parent      = File.dirname(file)
              destination = File.join("#{prepare_dir}/BUILD", parent)
      
              task_mkdir(destination, parents: true)
              copy_file(file, destination)
            end
          end

          def build : Nil
            write_rpm_spec
            create_rpm_file
          end

          def config_files
            project.config_files.map { |file| rpm_safe(file) }
          end

          # TODO: Revisit when testing
          def with_rpm_signing(&block : String -> String) : String
            directory   = Dir.mktmpdir
            destination = File.join(directory, "sign-rpm")
      
            render_template(SIGNING_TEMPLATE,
              destination: destination,
              mode: File::Permissions.new(0o700),
              variables: {
                passphrase: signing_passphrase,
              })
      
            block.call(destination)
          ensure
            task_remove_contents(directory)
            task_rmdir(directory)
          end

          protected def build_dir
            File.join(prepare_dir, "BUILD")
          end

          protected def copy_file(file, dest)
            Software::Commands::Copy.new(file, dest).execute
          end

          def write_rpm_spec
            scripts = SCRIPT_MAP.reduce({} of String => String) do |hash, (source, destination)|
              path = File.join(project.package_scripts_path, source.to_s)
      
              if File.file?(path)
                hash[destination] = File.read(path)
              end
      
              hash
            end

            # Get a list of all files
            files = (Dir.glob(["#{build_dir}/**/*"], true) - ["..", "."])
             .map { |path| build_filepath(path) }

            render_template(SPEC_TEMPLATE,
              destination: spec_file,
              variables: Crinja.variables({
                "name" => safe_package_name,
                "version" => safe_version.to_s,
                "iteration" => project.build_iteration.to_s,
                "vendor" => vendor,
                "license" => license,
                "summary" => summary,
                "dist_tag" => "#{dist_tag}\n",
                "maintainer" => project.maintainer,
                "homepage" => project.homepage,
                "description" => project.description,
                "safe_description" => project.description.gsub(/^\s*$/m, "."),
                "priority" => priority,
                "category" => category,
                "conflicts" => project.conflicts,
                "replaces" => project.replaces,
                "dependencies" => project.runtime_dependencies,
                "user" => project.package_user,
                "group" => project.package_group,
                "scripts" => scripts,
                "config_files" => config_files,
                "files" => files,
                "build_dir" => build_dir,
                "platform_family" => platform.family,
                "compression" => compression
              })
            )
          end

          def create_rpm_file
            command = String.build do |io|
              io <<  %{rpmbuild}
              io << %{ --target #{safe_architecture}}
              io << %{ -bb}
              io << %{ --buildroot #{prepare_dir}/BUILD}
              io << %{ --define '_topdir #{prepare_dir}'}
              io << " #{spec_file}"
            end

            on_output.call("RUNNING: #{command}")

            Software::Commands::Command.new(command)
              .forward_output(&on_output)
              .forward_error(&on_error)
              .execute

            begin
              Dir.glob(File.join(prepare_dir, "RPMS", "**", "*.rpm")).each do |file|
                Software::Commands::Copy.new(file, project.package_dir).execute
              end
            rescue ex 
              on_error.call("error on syncing rpm to package dir: #{ex}")
            end
          end

          protected def render_template(str, variables, destination : String, mode : File::Permissions = File::Permissions.new(0o755))
            Software::Commands::Template.new(src: str, dest: destination, mode: mode, vars: variables, string: true)
              .forward_output(&on_output)
              .forward_error(&on_error)
              .execute
          end

          def summary
            description_line_one = project.description.split("\n").first
            description_line_one.empty? ? "_" : description_line_one.split("\n").first
          end

          def compression
            compression_name = case compression_type
                              when :bzip2
                                "bzdio"
                               when :xz
                                "xzdio"
                              else # default to gzip
                                "gzdio"
                              end
            "w#{compression_level}.#{compression_name}"
          end

          def spec_file
            File.join(prepare_dir, "SPECS", "#{safe_package_name}.spec")
          end

          def rpm_file
            File.join(preapre_dir, "RPMS", safe_architecture, safe_package_name)
          end

          def build_filepath(path)
            filepath = rpm_safe("/" + path.gsub("#{build_dir}/", ""))
            return if config_files.includes?(filepath)
      
            full_path = build_dir + filepath.gsub("[%]", "%")
            # FileSyncer.glob quotes pathnames that contain spaces, which is a problem on el7
            full_path = full_path.gsub("\"", "")
            # Mark directories with the %dir directive to prevent rpmbuild from counting their contents twice.
            return mark_filesystem_directories(filepath) if !File.symlink?(full_path) && File.directory?(full_path)
      
            filepath
          end

          def mark_filesystem_directories(fsdir)
            if fsdir == "/" || fsdir == "/usr/lib" || fsdir == "/usr/share/empty"
              "%dir %attr(0555,root,root) #{fsdir}"
            elsif filesystem_directories.includes?(fsdir)
              "%dir %attr(0755,root,root) #{fsdir}"
            else
              "%dir #{fsdir}"
            end
          end

          def filesystem_directories
            FILESYSTEM_LIST.split("\n")
          end

          def query
            path = File.join(project.package_dir, package_name)
            Software::Commands::Command.new("rpm -qip #{path}")
              .forward_output(&on_output)
              .forward_error(&on_error)
              .execute
          end

          def list_files
            path = File.join(project.package_dir, package_name)
            Software::Commands::Command.new("rpm -qlp #{path}")
              .forward_output(&on_output)
              .forward_error(&on_error)
              .execute
          end

          def rpm_safe(string)
            string = "\"#{string}\"" if string[/\s/]?
      
            string.dup
              .gsub("[", "[\\[]")
              .gsub("*", "[*]")
              .gsub("?", "[?]")
              .gsub("%", "[%]")
          end

          def package_name
            "#{safe_package_name}-#{safe_version}-#{project.build_iteration}.#{platform.family}#{platform.version}.#{safe_architecture}.rpm"
          end

          # TODO: revisit to follow omnibus
          # https://github.com/chef/omnibus/blob/main/lib/omnibus/packagers/rpm.rb#L597
          def safe_version : String
            version = project.build_version.dup
            if version =~ /\-/
              if platform.family == "wrlinux"
                converted = version.tr("-", "_")
              else
                converted = version.tr("-", "~")
              end

              version = converted
            end
              
            if version =~ /\A[a-zA-Z0-9\.\+\~]+\z/
              version
            else
              version.gsub(/[^a-zA-Z0-9\.\+\~]+/, "_")
            end
          end

          def safe_architecture
            case kernel.machine
            when "i686"
              "i386"
            when "armv71"
              "armv7h1"
            when "armv61"
              if platform.family == "pidora"
                "armv6h1"
              else
                "armv61"
              end
            else
              kernel.machine
            end
          end
        end
      end
    end
  end
end
