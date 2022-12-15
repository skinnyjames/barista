require "./platform_family"
require "./linux/information"
require "./darwin/information"

module Barista
  module Behaviors
    module Software
      module OS
        module Information
          {% if flag?(:linux) %}
            include OS::Linux::Information
          {% elsif flag?(:darwin) %}
            include OS::Darwin::Information
          {% end %}

          include PlatformFamily
        end
      end
    end
  end
end
