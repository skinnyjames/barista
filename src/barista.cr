require "./barista/**"

module Barista
  VERSION = "0.1.0"

  macro project_file(filepath)
    {{ read_file(__DIR__ + "/barista" + filepath )}}
  end

  def self.project_file(filepath)
    project_file(filepath)
  end
end
