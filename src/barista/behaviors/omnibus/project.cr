module Barista
  module Behaviors
    module Omnibus
      module Project
        include Macros
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
        gen_method(:package_dir, String) { File.join(barista_dir, "pkg") }
        gen_method(:maintainer, String) { missing_attribute("maintainer") }
        gen_method(:package_user, String) { "root" }
        gen_method(:package_group, String) { "root" }
        gen_method(:package_scripts_path, String) { File.join(barista_dir, "package-scripts", name) }
        gen_method(:resources_path, String) { File.join(barista_dir, "resources") }

        BUILD_GIT_REVISION = {{ `git rev-parse HEAD`.stringify }}.strip

        @exclusions : Array(String) = [] of String

        def exclude(val : String)
          @exclusions << val
          @exclusions.dup
        end

        def clean
          Dir.cd(install_dir) { FileUtils.rm_r(Dir.children(".")) }
          Dir.cd(barista_dir) { FileUtils.rm_r(Dir.children(".")) }
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
