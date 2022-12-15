module Barista
  module Behaviors
    module Software
      module OS
        module Linux
          struct Memory
            getter :cpu_info

            @cpu_info : Hash(String, String?) = {} of String => String?

            def initialize
              init_cpu_info
            end

            def cpus
              cpu_info["CPU(s):"]?.try(&.to_i32)
            end

            def threads_per_core
              cpu_info["Thread(s) per core:"]?.try(&.to_i32)
            end

            def sockets
              cpu_info["Socket(s):"]?.try(&.to_i32)
            end

            def cores_per_socket
              cpu_info["Core(s) per socket:"]?.try(&.to_i32)
            end

            protected def init_cpu_info
              info = `lscpu | grep -E '^Thread.*|^Core.*|^Socket.*|^CPU.*' --ignore-case`
              h = info.split(/\s{2,}/).join("\n").split("\n")[0..-2].each_slice(2).to_h
              @cpu_info.merge!(h)
            end
          end
        end
      end
    end
  end
end
