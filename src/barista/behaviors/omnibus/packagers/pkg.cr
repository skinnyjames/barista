module Barista
  module Behaviors
    module Omnibus
      module Packagers
        class Pkg < Base
          DISTRIBUTION_TEMPLATE = Barista.project_file("/behaviors/omnibus/packagers/scripts/pkg/distribution.xml.hbs")
          LICENSE_TEMPLATE = Barista.project_file("/behaviors/omnibus/packagers/scripts/pkg/license.html.hbs")
          WELCOME_TEMPLATE = Barista.project_file("/behaviors/omnibus/packagers/scripts/pkg/welcome.html.hbs")
          BG_TEMPLATE = Barista.project_file("/behaviors/omnibus/packagers/scripts/pkg/background.png")
          ENTITLEMENTS_TEMPLATE = Barista.project_file("/behaviors/omnibus/packagers/scripts/pkg/entitlements.plist.hbs")

          SCRIPT_MAP = {
            :preinst => "preinstall",
            :postinst => "postinstall",
            :preinstall => "preinstall",
            :postinstall => "postinstall",
          }

          delegate(:license, to: @project)

          def initialize(@project : Barista::Behaviors::Omnibus::Project); end

          gen_supported("which pkgbuild", /pkgbuild not found/)
          gen_method(:identifier, String?) { nil }
          gen_method(:signing_identity, String?) { nil }
          gen_method(:codesigning_identity, String?) { nil }
          gen_method(:entitlements, Array(String)? ) { nil }
          gen_method(:license_template, String) { LICENSE_TEMPLATE }
          gen_method(:welcome_template, String) { WELCOME_TEMPLATE }
          gen_method(:distribution_template, String) { DISTRIBUTION_TEMPLATE }
          gen_method(:image, String) { BG_TEMPLATE }

          def supported? : Bool
            Pkg.supported?
          end

          def id : Symbol
            :pkg
          end

          def list_files
            path = File.join(project.package_dir, package_name)
            Software::Commands::Command.new("lsbom `pkgutil --bom #{path}`")
              .forward_output(&on_output)
              .forward_error(&on_error)
              .execute
          end

          def query
            path = File.join(project.package_dir, package_name)
            Software::Commands::Command.new("pkgutil --file-info #{path}")
              .forward_output(&on_output)
              .forward_error(&on_error)
              .execute
          end

          def configure : Nil
            task_mkdir(resources_path)
            task_mkdir(scripts_path)

            File.write(File.join(resources_path, "background.png"), image)

            Software::Commands::Template.new(
              src: license_template, 
              dest: File.join(resources_path, "license.html"),
              mode: File::Permissions.new(0o755),
              vars: Crinja.variables({
                "friendly_name" => project.name,
              }),
              string: true
            )
            .forward_output(&on_output)
            .forward_error(&on_error)
            .execute

            Software::Commands::Template.new(
              src: welcome_template, 
              dest: File.join(resources_path, "welcome.html"),
              mode: File::Permissions.new(0o755),
              vars: Crinja.variables({
                "friendly_name" => project.name,
              }),
              string: true
            )
            .forward_output(&on_output)
            .forward_error(&on_error)
            .execute
          end

          def build : Nil
            write_scripts
            sign_software
            build_component_pkg
            write_distribution_file
            build_product_pkg
          end

          def write_scripts
            SCRIPT_MAP.each do |source, dest|
              source_path = File.join(project.package_scripts_path, source.to_s)
              
              if File.file?(source_path)
                copy_to = File.join(scripts_path, dest)
                File.copy(source_path, copy_to)
              end
            end
          end

          def build_component_pkg
            command = <<-EOH
            pkgbuild \\
              --identifier "#{safe_identifier}" \\
              --version "#{safe_version}" \\
              --scripts "#{scripts_path}" \\
              --root "#{project.install_dir}" \\
              --install-location "#{project.install_dir}" \\
              --preserve-xattr \\

            EOH

            command += " --sign \"#{signing_identity}\"" if signing_identity
            command += " \"#{component_pkg}\""
            command += "\n"

            Dir.cd(staging_path) do
              `#{command}`
            end
          end

          def write_entitlements_file
            if etlm = entitlements
              Software::Commands::Template.new(
                src: ENTITLEMENTS_TEMPLATE,
                dest: entitlements_path,
                mode: File::Permissions.new(0o755),
                vars: Crinja.variables({
                  "entitlements" => etlm
                }),
                string: true
              )
              .forward_output(&on_output)
              .forward_error(&on_error)
              .execute
            end
          end

          def entitlements_path : String
            File.join(project.package_dir, "entitlements.plist")
          end

          def write_distribution_file
            Software::Commands::Template.new(
              src: distribution_template, 
              dest: File.join(staging_path, "Distribution.xml"),
              mode: File::Permissions.new(0o755),
              vars: Crinja.variables({
                "friendly_name" => project.name,
                "version" => safe_version,
                "identifier" => safe_identifier,
                "component_pkg" => component_pkg,
                "host_architecture" => safe_architecture
              }),
              string: true
            )
            .forward_output(&on_output)
            .forward_error(&on_error)
            .execute
          end

          def package_name
            "#{safe_package_name}-#{safe_version}-#{safe_build_iteration}.#{safe_architecture}.pkg"
          end

          def component_pkg
            "#{safe_base_package_name}-core.pkg"
          end

          def safe_architecture : String
            kernel.machine || "unknown"
          end
          
          def safe_base_package_name : String  
            strip_non_alphanumeric(project.package_name.downcase)
          end

          def safe_identifier
            return identifier if identifier

            maintainer = strip_non_alphanumeric(project.maintainer.downcase)
            "test.#{maintainer}.pkg.#{safe_base_package_name}"
          end

          def safe_build_iteration
            project.build_iteration
          end

          def safe_version
            project.build_version.gsub(/[^a-zA-Z0-9\.\+\-]+/, "-")
          end

          def find_linked_libs(file_path) : Array(String)
            Process.run("otool", ["-L", file_path], shell: true) do |process|
              process.output.scan(/#{Regex.escape(project.install_dir)}\S*/)
            end
          end

          def build_product_pkg
            command = String.build do |io|
              io << "productbuild --distribution \"#{staging_path}/Distribution.xml\" --resources \"#{resources_path}\""
              io << " --sign \"#{signing_identity}\"" if signing_identity
              io.puts " \"#{final_pkg}\""
            end

            Dir.cd(staging_path) do
              `#{command}`
            end
          end

          def sign(bin, hardened_runtime = true)
            command = String.build do |io|
              io << "codesign -s '#{codesigning_identity}' '#{bin}'"
              io << " --timestamp"
              io << " --options=runtime" if hardened_runtime
              io << " --entitlements #{entitlements_path}" if entitlements_path && File.exists?(entitlements_path) && hardened_runtime
              io.puts " --force"
            end

            Software::Commands::Command.new(command)
              .forward_output(&on_output)
              .forward_error(&on_error)
              .execute
          end

          def final_pkg
            File.join(project.package_dir, package_name)
          end

          def resources_path
            File.join(prepare_dir, "Resources")
          end

          def scripts_path
            File.join(prepare_dir, "Scripts")
          end

          def staging_path
            prepare_dir
          end

          def sign_software(hardened_runtime = true)
            if codesigning_identity
              ["lib", "bin"].each do |type|
                Dir.glob("#{install_dir}/embedded/#{type}/**/*") do |file|
                  next if File.directory?(file)
                  puts "signing #{file}"
                  sign(file, hardened_runtime)
                end
              end
            end
          end

          def is_binary?(bin) : Bool
            return false unless File.file?(bin) && File.executable?(bin) && !File.symlink?(bin)

            true
          end

          private def strip_non_alphanumeric(str : String)
            str.gsub(/[^a-zA-Z0-9]+/, "")
          end
        end
      end
    end
  end
end
