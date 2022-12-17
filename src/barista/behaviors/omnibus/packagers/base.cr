module Barista
  module Behaviors
    module Omnibus
      module Packagers
        abstract class Base
          include Software::GenericCommands
          include Software::OS::Information
          include Omnibus::Macros
          include Software::Emittable

          @prepare_dir : String?

          getter :project

          delegate(:install_dir, to: @project)

          def initialize(@project : Barista::Behaviors::Omnibus::Project); end

          abstract def configure : Nil
          abstract def build : Nil
          abstract def id : Symbol
          abstract def supported? : Bool

          def package_name
            project.package_name
          end

          def safe_package_name : String
            return project.package_name.dup if project.package_name =~ /\A[a-z0-9\.\+\-]+\z/

            project.package_name.downcase.gsub(/[^a-z0-9\.\+\-]+/, "-")
          end

          def exclusions
            ex = project.exclusions.map { |exclusion| File.join(project.install_dir, exclusion) }
            ex + %w{
              **/.git
              **/.hg
              **/.svn
              **/.gitkeep
            }
          end
          
          protected def sync_install_to(dest : String)
            task_mkdir(dest, parents: true)

            Software::Merger.new(project.install_dir, dest, exclude: exclusions).execute(keep_links: true)
          end

          protected def package_path
            Path[File.join(project.package_dir, safe_package_name)].expand
          end

          protected def prepare_dir : String
            prepare_path = @prepare_dir
            return prepare_path if prepare_path
          
            tmp = File.join(Dir.tempdir, safe_package_name)
            task_mkdir(tmp, parents: true)

            @prepare_dir = tmp
          end

          protected def prepare_dir_path(file_name : String)
            File.join(prepare_dir, file_name)
          end

          protected def resources_path
            File.join(project.resources_path, id)
          end

          protected def resource_path(file_name)
            File.join(resources_path, file_name)
          end

          def run
            task_mkdir(project.package_dir)

            configure
            build    
          ensure
            cleanup        
          end

          def cleanup
            task_rmdir(prepare_dir)
          end

          macro gen_supported(cmd, regex_test)
            def self.supported? : Bool
              o = [] of String

              begin
                Software::Commands::Command.new({{ cmd }})
                  .collect_output(o)
                  .collect_error(o)
                  .execute

                not_supported = o.any? { |l| Regex.new({{ regex_test.stringify }}).matches?(l) }
                !not_supported
              rescue ex : Software::CommandError
                false
              end
            end
          end
        end
      end
    end
  end
end
