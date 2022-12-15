module Barista
  module Behaviors
    module Software
      module OS
        module Darwin
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
              cpu_info["machdep.cpu.thread_count"]?.try(&.to_i32)
            end

            def cores
              cpu_info["machdep.cpu.core_count"]?.try(&.to_i32)
            end

            def init_cpu_info
              info = `sysctl -a | grep machdep.cpu`
              num_cpus = `sysctl -n hw.ncpu`
              h = info.split("\n").map(&.split(": "))[0..-2].to_h
              h["CPU(s):"] = num_cpus
              @cpu_info.merge!(h)
            end
          end
        end
      end
    end
  end
end
