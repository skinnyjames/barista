require "./software"

module Barista
  module Behaviors
    module Omnibus
      class MissingRequiredAttribute < Exception; end

      module Project
      end

      module Task
        include Software::Task 

        @version : String?
        @cache : Bool = true
        @name : String?

        abstract def project : Barista::Project
        abstract def configure : Nil

        def execute
          configure
        end

        def version(val : String? = nil) : self
          if val.nil?
            @version || missing_attribute("version")
          else
            @version = val
          end

          self
        end

        # Define if a cached should be used for this task
        def cache(val : Bool? = nil) : self
          if val.nil?
            @cache
          else
            @cache = val
          end

          self
        end

        private def missing_attribute(attribute)
          raise MissingRequiredAttribute.new("#{self.class.name} is missing project attribute `#{attribute}`")
        end
      end
    end
  end
end
