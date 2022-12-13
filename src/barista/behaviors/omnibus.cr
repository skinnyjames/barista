require "./software"
require "./omnibus/**"

module Barista
  module Behaviors
    module Omnibus
      class MissingRequiredAttribute < Exception; end

      module Project
        abstract def install_dir
        abstract def barista_dir
        abstract def registry
      end

      module Task
        include Software::Task
        include PlatformEnv

        @version : String?
        @cache : Bool = true
        @project : Barista::Behaviors::Omnibus::Project

        getter :project

        delegate(:install_dir, to: @project)
        delegate(:barista_dir, to: @project)

        abstract def configure : Nil

        def initialize(@project : Barista::Behaviors::Omnibus::Project)
          super()

          configure
        end

        def execute
          build
          # make needed directories
          task_mkdir(install_dir, parents: true)
          task_mkdir(source_dir, parents: true)
          
          fetch_source

          # execute to install directory
          @commands.each(&.execute)
        end

        private def fetch_source
          source.try do |source|
            begin
              source.execute(File.join(barista_dir, "source"), name)
            rescue ex : Software::Fetchers::RetryExceeded
              on_error.call("Failed to fetch: #{ex}")
              raise ex
            end
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
          File.join(barista_dir, "source", name)
        end

        def command(str : String, chdir : String = source_dir, **args)
          super(str, **args.merge(chdir: chdir))
        end

        def copy(src, dest, chdir : String = source_dir, **args)
          super(src, dest, **args.merge(chdir: chdir))
        end

        def sync(src, dest, exclusions = [] of String, **args, &block)
          if Path[src].absolute?
            source = src
            exclusions = exclude
          else
            source = File.join(source_dir, src)
            exclusions = exclude.map { |e| File.join(source_dir, e) }
          end
    
          super(source, dest, **args.merge(exclusions: exclusions), &block)
        end

        def sync(src, dest, exclusions = [] of String, **args)
          if Path[src].absolute?
            source = src
            exclusions = exclude
          else
            source = File.join(source_dir, src)
            exclusions = exclude.map { |e| File.join(source_dir, e) }
          end
    
          super(source, dest, **args.merge(exclusions: exclusions))
        end

        def link(src, dest, chdir : String = source_dir, **args)
          super(src, dest, **args.merge(chdir: chdir))
        end

        def patch(path : String, chdir : String = source_dir, **args)
          super(path, **args.merge(chdir: chdir))
        end

        def version(val : String? = nil) : String
          if val.nil?
            return @version || missing_attribute("version")
          else
            @version = val
          end
        end

        # Define if a cached should be used for this task
        def cache(val : Bool? = nil) : Bool
          if val.nil?
            return @cache || true
          else
            @cache = val
          end
        end

        def shasum : String
          digest = Digest::SHA256.new

          @commands.each do |cmd|
            digest << cmd.description
          end
  
          # include upstream dependencies in this checksum
          # if any upstream changes, this tasks checksum
          # will change too.
     
          project.registry.upstreams(name).each do |task|
            digest << task.as(Barista::Behaviors::Omnibus::Task).shasum
          end
  
          digest.hexfinal
        end

        private def missing_attribute(attribute)
          raise MissingRequiredAttribute.new("#{self.class.name} is missing project attribute `#{attribute}`")
        end
      end
    end
  end
end
