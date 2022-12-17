module Barista
  module Behaviors
    module Omnibus
      module Project
        include Macros
        include Software::OS::Information
        include Software::GenericCommands

        @packager : Packagers::Base?

        gen_method(:install_dir, String) { missing_attribute("install_dir") }
        gen_method(:barista_dir, String) { missing_attribute("barista_dir") }
        gen_method(:build_version, String) { missing_attribute("build_version") }
        gen_method(:build_git_revision, String) { BUILD_GIT_REVISION }
        gen_method(:build_iteration, Int32) { 1 }
        gen_method(:cache, Bool) { false }
        gen_method(:description, String) { "the full stack of #{name}" }
        gen_method(:homepage, String) { missing_attribute("homepage") }
        gen_method(:license, String) { "Unspecified" }
        gen_method(:package_name, String) { name }
        gen_method(:package_dir, String) { File.join(barista_dir, "package") }
        gen_method(:maintainer, String) { missing_attribute("maintainer") }
        gen_method(:package_user, String) { "root" }
        gen_method(:package_group, String) { "root" }
        gen_method(:package_scripts_path, String) { File.join(barista_dir, "package_scripts", name) }
        gen_method(:resources_path, String) { File.join(barista_dir, "resources") }
        gen_method(:package_name, String) { name }

        BUILD_GIT_REVISION = {{ `git rev-parse HEAD`.stringify }}.strip

        gen_collection_method(:exclude, :exclusions, String)
        gen_collection_method(:runtime_dependency, :runtime_dependencies, String)
        gen_collection_method(:conflict, :conflicts, String)
        gen_collection_method(:replace, :replaces, String)
        gen_collection_method(:config_file, :config_files, String)
        gen_collection_method(:extra_package_file, :extra_package_files, String)

        def clean
          Dir.cd(install_dir) { FileUtils.rm_r(Dir.children(".")) }
          Dir.cd(barista_dir) { FileUtils.rm_r(Dir.children(".")) }
        end

        def clean!
          clean
          task_rmdir(install_dir)
          task_rmdir(barista_dir)
        end
        
        def manifest_json
          Manifest.new(self).to_json
        end

        def cache_dir
          File.join(barista_dir, "cache")
        end

        def source_dir
          File.join(barista_dir, "source")
        end

        def stage_dir
          File.join(barista_dir, "stage")
        end

        def tasks : Barista::Behaviors::Omnibus::Task
          registry.tasks
        end

        def packager : Packagers::Base
          @packager ||= Packager.discover(self)
        end

        def package
          packager.run
        end

        def validate_package_fields
          install_dir
          homepage
          license
          build_version
          build_iteration
          description
          homepage
          license
          package_name
          package_dir
          maintainer
          package_user
          package_group
          package_scripts_path
          package_name
          barista_dir
        end

        protected def shasum : String
          digest = Digest::SHA256.new

          digest << name
          digest << install_dir

          digest.hexfinal
        end

        abstract def registry
      end
    end
  end
end
