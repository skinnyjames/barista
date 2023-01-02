module Barista
  module Behaviors
    module Omnibus
      class LicenseMissingError < Exception; end
      class LicenseCollector
        getter :project
        
        def initialize(@project : Barista::Behaviors::Omnibus::Project); end

        # Copies the license files for the task into 
        # the target directory and appends a description to the summary. 
        def <<(task : Barista::Behaviors::Omnibus::Task)
          return if task.virtual
          FileUtils.mkdir_p(File.join(task.smart_install_dir, "LICENSES"))

          task.license_files.each do |path|
            raise_if_missing(task, path)

            copy_to_destination(
              license_location(task, path),
              output_location(task, path, staged: true)
            )
          end
        end

        # Writes the license summary for the project and all of its tasks
        def write_summary
          FileUtils.mkdir_p(project.install_dir)

          File.open(project.license_file_path, "w") do |io|
            io.puts "#{project.name} #{project.build_version} license: \"#{project.license}\""
            io.puts ""
            io.puts project.license_content
            io.puts ""
            io.puts tasks_summary unless tasks_summary.blank?
          end
        end

        def tasks_summary
          String.build do |io|
            project.registry.tasks.each do |registry_task|
              task = registry_task.as(Barista::Behaviors::Omnibus::Task)
              next if task.virtual

              io.puts "This product bundles #{task.name} #{task.version},"
              io.puts "which is available under a \"#{task.license}\" License."
              
              unless task.license_files.empty?
                io.puts "For details, see:"
                task.license_files.each do |file|
                  io.puts output_location(task, file)
                end
              end
              io.puts ""
            end
          end
        end

        private def copy_to_destination(source, destination)
          FileUtils.cp(source, destination)
          File.chmod(destination, File::Permissions.new(0o644))
        end

        private def raise_if_missing(task, path)
          unless File.exists?(license_location(task, path))
            raise LicenseMissingError.new("License file #{path} does not exist for #{task.name}")
          end
        end

        private def license_location(task, path)
          File.join(task.source_dir, path)
        end

        private def output_location(task, where, staged : Bool = false)
          dest_directory = staged ? task.smart_install_dir : project.install_dir
          File.join(dest_directory, "LICENSES", "#{task.name}-#{Path.new(where).parts.last}")
        end
      end
    end
  end
end
