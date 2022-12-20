module Barista
  module Behaviors
    module Omnibus
      class Cacher
        include Barista::Behaviors::Software::GenericCommands

        getter :task
    
        def initialize(@task : Barista::Behaviors::Omnibus::Task); end
    
        def tag
          task.tag
        end
    
        def name
          task.name
        end
    
        # A method that takes a path to a `.tar.gz`
        # and unpacks it to the appropriate internal directory
        def unpack(path_to_tarball : String)
          status = Process.run(
            "tar -xvf #{path_to_tarball} -C#{unpack_cache_here!} --strip-components=#{strip}",
            shell: true,
            output: Process::Redirect::Close,
            error: Process::Redirect::Close
          )
          status.exit_code.zero? ? true : false
        end
    
        # The number of components to strip when using 
        # `tar -xvf <path> --strip-components=<strip>`
        def strip : Int32
          Path[task.stage_dir].parts.size - 1
        end
    
        # A filename that includes the `.tar.gz` extension
        def filename
          "#{task.tag}.tar.gz"
        end
    
        # Log an informational message for this task
        def info(&block : -> String)
          meta.info(&block)
        end
    
        # Log an error message for this task
        def error(&block : -> String)
          meta.error(&block)
        end
    
        # The location for unpacking the build artifact 
        # when handling manually.  
        # 
        # `#unpack!` is preferred.
        def unpack_cache_here!
          task_mkdir(task.stage_dir, parents: true)
    
          task.stage_dir
        end
      end
    end
  end
end
