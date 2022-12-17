require "./platform_family"
require "./kernel"
require "./linux/information"
require "./darwin/information"

module Barista
  module Behaviors
    module Software
      module OS          
        module Information
          @kernel : Kernel?

          {% if flag?(:linux) %}
            include OS::Linux::Information
          {% elsif flag?(:darwin) %}
            include OS::Darwin::Information
          {% end %}

          include PlatformFamily

          def kernel : Kernel
            @kernel ||= Kernel.new
          end
        end
      end
    end
  end
end
