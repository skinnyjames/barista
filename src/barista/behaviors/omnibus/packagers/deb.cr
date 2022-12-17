require "./base"

module Barista
  module Behaviors
    module Omnibus
      module Packagers
        class Deb < Base
          delegate(:license, to: @project)

          gen_supported("which dpkg-deb", /no dpkg-deb/)
          
          def supported? : Bool
            Deb.supported?
          end

          def initialize(@project : Barista::Behaviors::Omnibus::Project); end

          def id : Symbol
            :deb
          end

          def configure : Nil
            sync_install_to(File.join(prepare_dir, project.install_dir))

            task_mkdir(debian_dir, parents: true)
          end

          def build :  Nil
            write_control_file
            write_conffiles_file
            write_scripts
            write_md5_sums
            create_deb_file
          end

          def write_control_file
            File.open(File.join(debian_dir, "control"), "w") do |fh|
              fh.puts "Package: #{safe_package_name}"
              fh.puts "Version: #{safe_version}-#{project.build_iteration}"
              fh.puts "License: #{license}"
              fh.puts "Architecture: #{safe_architecture}"
              fh.puts "Maintainer: #{project.maintainer}"
              fh.puts "Installed-Size: #{package_size}"
  
              unless project.runtime_dependencies.empty?
                fh.puts "Depends: #{project.runtime_dependencies.join(", ")}"
              end
  
              unless project.conflicts.empty?
                fh.puts "Conflicts: #{project.conflicts.join(", ")}"
              end
  
              unless project.replaces.empty?
                fh.puts "Replaces: #{project.replaces.join(", ")}"
              end
  
              fh.puts "Section: #{section}"
              fh.puts "Priority: #{priority}"
              fh.puts "Homepage: #{project.homepage}"
              fh.puts "Description: #{clean_description}"
            end
          end

          def write_conffiles_file
            return if project.config_files.empty?
  
            File.open(File.join(debian_dir, "conffiles"), "w") do |fh|
              project.config_files.each do |file|
                fh.puts file
              end
            end
          end

          def write_scripts
            %w{preinst postinst prerm postrm}.each do |script|
              path = File.join(project.package_scripts_path, script)
  
              if File.file?(path)
                File.copy(path, "#{debian_dir}/#{script}")
                File.chmod("#{debian_dir}/#{script}", 0o755) 
              end
            end
          end
           
          def write_md5_sums
            path = "#{prepare_dir}/**/*"
            paths = Dir[path, match_hidden: true]
  
            hash = shasums(paths)
            
            File.open(File.join(debian_dir, "md5sums"), "w") do |fh|
              hash.each do |path, checksum|
                fh.puts "#{checksum} #{path}"
              end
            end
          end

          def create_deb_file
            Dir.cd(project.package_dir) do 
              `dpkg-deb #{compression_params} -D --build #{prepare_dir} #{package_name}`
            end
          end
            
          def package_name
            "#{safe_package_name}_#{safe_version}-#{project.build_iteration}_#{safe_architecture}.deb"
          end

          private def package_size
            paths = Dir.glob(File.join(prepare_dir, project.install_dir, "**", "*"))

            return 0 if paths.size == 0

            Software::SizeCalculator.new(workers: workers, paths: paths).execute
          end

          private def clean_description
            first, *rest = project.description.split("\n")
            clean = rest.map do |line|
              line =~ /^ *$/ ? " ." : " #{line}"
            end.join("\n")
  
            "#{first}\n#{clean}"
          end

          private def workers
            project.memory.cpus.try { |c| c - 1 } || 1
          end
  
          private def priority
            "extra"
          end
  
          private def section
            "misc"
          end
  
          private def render_template(source, dest, *, mode : File::Permissions, vars = {} of String => String)
            Software::Commands::Template.new(source: source, dest: dest, mode: mode, vars: vars).execute
          end
  
          private def safe_version
            version = project.build_version.dup
  
            if version =~ /\-/
              version = version.tr("-", "~")
            end
  
            version.gsub(/[^a-zA-Z0-9\.\+\:\~]+/, "_")
          end
  
          private def safe_architecture : String
            `dpkg --print-architecture`.split("\n").first || "noarch"
          end
  
          private def debian_dir
            @debian_dir ||= File.join(prepare_dir, "DEBIAN")
          end
  
          private def compression_params
            "-z#{compression_level} -Z#{compression_type}"
          end
  
          private def compression_level
            "9"
          end
  
          private def compression_type
            "zstd"
          end

          def query
            path = File.join(project.package_dir, package_name)
            Software::Commands::Command.new("dpkg-deb -I #{path}")
              .on_output { |s| on_output.call(s) }
              .on_error { |s| on_error.call(s) }
              .execute
          end

          def list_files
            path = File.join(project.package_dir, package_name)
            Software::Commands::Command.new("dpkg -c #{path}")
              .on_output { |s| on_output.call(s) }
              .on_error { |s| on_error.call(s) }
              .execute
          end
  
          private def shasums(paths : Array(String))
            if paths.size <= workers
              slice_size = paths.size.to_i32
            else
              slice_size = (paths.size / workers).round(3).to_i32
            end

            path_arrs = paths.each_slice(slice_size).to_a
            sha_channel = Channel(Hash(String, String)).new
  
            path_arrs.map do |pths|
              spawn do
                aggregate = pths.reduce({} of String => String) do |hash, path|
                  if File.file?(path) && !File.symlink?(path) && !(File.dirname(path) == debian_dir)
                    relative_path = path.gsub("#{prepare_dir}/", "")
                    hash[relative_path] = Digest::MD5.new.file(path).final.hexstring
                  end
                  
                  hash
                end
  
                sha_channel.send(aggregate)
              end
            end
  
            sha_paths = {} of String => String
  
            path_arrs.size.times do
              dict = sha_channel.receive
              sha_paths.merge!(dict)
            end
  
            sha_paths
          end
        end
      end
    end
  end
end
