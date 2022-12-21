require "./software"

module Barista
  module Behaviors
    module Omnibus
      class MissingRequiredAttribute < Exception; end
      
      module Macros
        macro gen_method(name, type, &block)
          {% if type.resolve == Bool %}
            @{{ name.id }} : Bool = {{ block.body }}

            def {{ name.id }}(val : Bool? = nil)
              if val.nil?
                @{{ name.id }}
              else
                @{{ name.id }} = val
              end
            end
          {% else %}
            @{{ name.id }} : {{ type }}? = nil

            def {{ name.id }}(val : {{ type.id }}? = nil)
              if val.nil? 
                @{{ name.id }} || {{ block.body }}
              else
                @{{ name.id }} = val
              end
            end
          {% end %}
        end

        macro gen_collection_method(name, var_name, type)
          getter {{ var_name.id }}

          @{{ var_name.id }} = [] of {{ type }}

          def {{ name.id }}(val : {{ type.id }})
            @{{ var_name.id }} << val
            @{{ var_name.id }}.dup
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
