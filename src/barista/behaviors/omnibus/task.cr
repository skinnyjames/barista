module Barista
  module Behaviors
    module Omnibus
      module Task
        include Macros
        include Software::Task
        include PlatformEnv

        @version : String?
        @cache : Bool = true
        @project : Barista::Behaviors::Omnibus::Project
        @built : Bool = false

        getter :project, :callbacks

        delegate(:install_dir, to: @project)
        delegate(:barista_dir, to: @project)
        delegate(:license_collector, to: @project)

        abstract def configure : Nil

        def initialize(
          @project : Barista::Behaviors::Omnibus::Project, 
          @callbacks : Barista::Behaviors::Omnibus::CacheCallbacks = Barista::Behaviors::Omnibus::CacheCallbacks.new
        )
          super()

          configure
        end

        def execute
          unless @built
            build
            @built = true
          end

          # make needed directories
          task_mkdir(install_dir, parents: true)
          task_mkdir(source_dir, parents: true)
          task_mkdir(stage_install_dir, parents: true)

          return if build_from_cache

          fetch_source

          # execute to install directory
          @commands.map(&.execute)

          # copy licenses over
          license_collector << self

          if use_cache?
            update_cache
            
            Software::Merger.new(stage_dir, "/").execute(keep_links: preserve_symlinks)
          end
        end

        private def fetch_source
          source.try do |source|
            begin
              source.execute(project.source_dir, fetching_dir)
            rescue ex : Software::Fetchers::RetryExceeded
              on_error.call("Failed to fetch: #{ex}")
              raise ex
            end
          end
        end

        private def build_from_cache
          return false unless use_cache? 

          on_output.call("attempting to restore from cache.")

          restored = restore

          if !restored
            on_error.call("cache restore failed.")
            false
          else
            on_output.call("cache restore succeeded.")
            true
          end
        end

        # Define the source code to fetch when building this project
        # 
        # Currently only supports `Barista::Behaviors::Omnibus::Fetchers::Net`
        def source(url : String, **opts)
          @source = Software::Fetchers::Net.new(url, **opts)

          self
        end

        # Returns a configured fetcher if one exists.
        def source : Software::Fetchers::Net?
          @source
        end

        def source_dir
          dir = File.join(project.source_dir, name)
          if path = relative_path
            dir = File.join(dir, path)
          end
          
          dir
        end

        def fetching_dir
          if path = relative_path
            File.join(name, path)
          else
            name
          end
        end

        def stage_install_dir
          File.join(project.stage_dir, name, project.install_dir)
        end

        def stage_dir
          File.join(project.stage_dir, name)
        end

        def smart_install_dir
          use_cache? ? stage_install_dir : install_dir
        end

        def mkdir(dir, **args)
          dir = File.join(source_dir, dir) unless Path[dir].absolute?
          super(dir, **args)
        end

        def command(str : String, chdir : String = source_dir, **args)
          super(str, **args.merge(chdir: chdir))
        end

        def copy(src, dest, chdir : String = source_dir, **args)
          super(src, dest, **args.merge(chdir: chdir))
        end

        def bin(exe, command, **args)
          binary = File.join(install_dir, "embedded", "bin", exe)
          command("#{binary} #{command}", **args)
        end

        def sync(src, dest, exclude = [] of String, **args, &block : Software::Merger::Strategy)
          if Path[src].absolute?
            source = src
            exclusions = exclude
          else
            source = File.join(source_dir, src)
            exclusions = exclude.map { |e| File.join(source_dir, e) }
          end
    
          super(source, dest, **args.merge(exclude: exclusions), &block)
        end

        def sync(src, dest, exclude = [] of String, **args)
          if Path[src].absolute?
            source = src
            exclusions = exclude
          else
            source = File.join(source_dir, src)
            exclusions = exclude.map { |e| File.join(source_dir, e) }
          end
    
          super(source, dest, **args.merge(exclude: exclusions))
        end

        def link(src, dest, chdir : String = source_dir, **args)
          super(src, dest, **args.merge(chdir: chdir))
        end

        def patch(path : String, chdir : String = source_dir, **args)
          super(path, **args.merge(chdir: chdir))
        end

        gen_method(:version, String) { missing_attribute("version") }
        gen_method(:cache, Bool) { true }
        gen_method(:license, String) { "Unspecified" }
        gen_method(:source_type, String) { "url" }
        gen_method(:relative_path, String) { nil }
        gen_method(:virtual, Bool) { false }
        gen_method(:preserve_symlinks, Bool) { true }
        gen_collection_method(:license_file, :license_files, String)

        def use_cache?
          project.cache && cache
        end

        def to_manifest_entry
          ManifestEntry.new(
            name,
            source_type: source_type,
            locked_version: version,
            locked_source: source.try(&.uri.to_s) || "",
            described_version: version,
            license: license,
          )
        end

        def tag
          prefix = project.cache_tag_prefix || ""

          [prefix, name, shasum].reject(&.blank?).join("-")
        end

        def shasum : String
          digest = Digest::SHA256.new

          digest << (version || "") unless virtual
          digest << (source.try(&.uri.to_s) || "")
          digest << license
          
          license_files.each do |file|
            digest << file
          end

          @commands.each do |cmd|
            digest << cmd.description
          end

          digest << project.shasum
  
          # include upstream dependencies in this checksum
          # if any upstream changes, this tasks checksum
          # will change too.
          project.registry.upstreams(name).each do |task|
            digest << task.as(Barista::Behaviors::Omnibus::Task).shasum
          end
  
          digest.hexfinal
        end

        def restore
          info = Cacher.new(self)

          return false unless (callbacks.fetch.try(&.call(info)) || false)
                    
          Software::Merger.new(stage_dir, "/").execute(keep_links: preserve_symlinks)
          
          true
        end

        def update_cache
          return false unless Dir.exists?(stage_dir)

          Process.run(
            "tar czvf \"#{stage_dir}.tar.gz\" #{stage_dir}",
            shell: true,
            output: Process::Redirect::Close,
            error: Process::Redirect::Close
          )

          callbacks.update.try(&.call(self.as(Barista::Behaviors::Omnibus::Task), "#{stage_dir}.tar.gz"))
        end
      end
    end
  end
end
