require "./software"

module Barista
  module Behaviors
    module Omnibus
      class MissingRequiredAttribute < Exception; end
      
      module Macros
        macro gen_method(name, type, &block)
          @{{ name.id }} : {{ type }}? = nil

          def {{ name.id }}(val : {{ type.id }}? = nil)
            if val.nil? 
              @{{ name.id }} || {{ block.body }}
            else
              @{{ name.id }} = val
            end
          end
        end

        private def missing_attribute(attribute)
          raise MissingRequiredAttribute.new("#{self.class.name} is missing project attribute `#{attribute}`")
        end
      end
    end
  end
end

require "./omnibus/**"
