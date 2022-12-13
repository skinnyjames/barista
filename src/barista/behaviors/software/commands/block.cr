module Barista
  module Behaviors
    module Software
      module Commands
        class Block < Base
          getter :name, :block
      
          def initialize(@name : String? = nil, &block : ->)
            @block = block
          end
    
          def execute
            block.call
          end

          def description : String
            String.build do |io|
              io << name
            end
          end
        end
      end
    end
  end
end
