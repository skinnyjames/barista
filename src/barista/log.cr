module Barista
  module Log
    Logger = ::Log.for(self)

    def self.level=(level)
      Logger.level = level
    end

    def self.backend(val : ::Log::Backend)
      Logger.backend = val
    end

    def self.info(caller, *, color : Symbol? = :default, &block : -> String | IO)
      output = block.call
      output.each_line do |line|
        Logger.info { "#{caller.colorize(color)}> #{line.strip}" }
      end
    end

    def self.error(caller, *, color : Symbol? = :default, &block : -> String | IO)
      output = block.call
      output.each_line do |line|
        Logger.error { "#{caller.colorize(color)}> #{line.strip.colorize(:red)}" }
      end
    end

    def self.warn(caller, *, color : Symbol? = :default, &block : -> String | IO)
      output = block.call
      output.each_line do |line|
        Logger.warn { "#{caller.colorize(color)}> #{line.strip.colorize(:yellow)}" }
      end
    end

    def self.debug(caller, *, color : Symbol? = :default, &block : -> String | IO)
      output = block.call
      output.each_line do |line|
        Logger.debug { "#{caller.colorize(color)}> #{line.strip.colorize(:light_gray)}" }
      end
    end
  end

  class RichLogger
    getter :color, :name
    def initialize(@color : Symbol, @name : String); end

    def info(&block : -> String | IO)
      Log.info(name, color: color, &block)
    end

    def error(&block : -> String | IO)
      Log.error(name, color: color, &block)
    end

    def debug(&block : -> String | IO)
      Log.debug(name, color: color, &block)
    end

    def warn(&block : -> String | IO)
      Log.warn(name, color: color, &block)
    end
  end
end