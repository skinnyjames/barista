module Barista
  module Behaviors
    module Brew
      lib LibC
        fun setsid : Int32
        fun getsid(pid : Int64) : Int64
        fun setpgid(pid : Int64, pgid : Int64) : Int32

        fun geteuid : Int64
        fun seteuid(uid : Int64) : Int32
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

        def self.get_euid : Int64
          LibC.geteuid.as(Int64)
        end

        def self.set_euid(uid)
          res = LibC.seteuid(uid)
          raise "Change effective uid error> #{Errno.value}" unless res.zero?
        end
      end
    end
  end
end
