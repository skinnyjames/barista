module Barista
  module Behaviors
    module Software
      module GenericCommands
        # Makes a directory at `directory` location
        # 
        # By default uses `mkdir -p`
        private def task_mkdir(directory : String, parents : Bool? = true)
          parents ? FileUtils.mkdir_p(directory) : FileUtils.mkdir(directory)
        end

        private def task_remove_contents(directory : String)
          FileUtils.rm_rf(Dir.children(directory)) if Dir.exists?(directory)
        end

        private def task_rmdir(directory : String)
          FileUtils.rm_rf(directory) if Dir.exists?(directory)
        end
      end
    end
  end
end
