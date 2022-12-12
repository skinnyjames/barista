module Barista
  module Behaviors
    module Software
      module Commands
        class Sync < Base
          getter :src, :dest, :exclude, :strategy

          @strategy : Merger::Strategy? = nil

          def initialize(@src : String, @dest : String, @exclude = [] of String, &strategy : Merger::Strategy)
            @strategy = strategy
          end

          def initialize(@src : String, @dest : String, @exclude = [] of String); end

          def execute
            on_output.try(&.call("Merging #{src} to #{dest}"))

            if s = strategy
              Merger.new(src, dest, exclude: exclude, &s).execute
            else
              Merger.new(src, dest, exclude: exclude).execute
            end
          end
          
          def description : String
            String.build do |io|
              io << src
              io << dest
              io << exclude.join(", ")
              io << "with block" if strategy
            end
          end
        end
      end
    end
  end
end
