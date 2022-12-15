require "./platform"
require "./memory"

module Barista
  module Behaviors
    module Software
      module OS
        module Darwin
          module Information
            @platform : Platform? = nil
            @memory : Memory? = nil

            def platform
              @platform ||= Platform.new
            end

            def memory
              @memory ||= Memory.new
            end
          end
        end
      end
    end
  end
end

