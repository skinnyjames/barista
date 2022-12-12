module Barista
  module Util
    module GenericCommands
      # Makes a directory at `directory` location
      # 
      # By default uses `mkdir -p`
      def mkdir(directory : String, recursive : Bool? = true)
        recursive ? FileUtils.mkdir_p(directory) : FileUtils.mkdir(directory)
      end

      def remove_contents(directory : String)
        FileUtils.rm_rf(Dir.children(directory)) if Dir.exists?(directory)
      end
    end
  end
end
