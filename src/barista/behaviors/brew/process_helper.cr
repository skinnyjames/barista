module Barista
  module Behaviors
    module Brew
      lib LibC
        fun setsid : Int32
        fun getsid(pid : Int64) : Int64
        fun setpgid(pid : Int64, pgid : Int64) : Int32
      end

      class ProcessHelper
        def self.get_sid(pid)
          LibC.getsid(pid)
        end

        def self.set_sid
          LibC.setsid
        end

        def self.set_pgid(pid, pgid)
          LibC.setpgid(pid, pgid)
        end
      end
    end
  end
end