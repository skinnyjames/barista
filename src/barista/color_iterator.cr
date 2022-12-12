module Barista
  struct ColorIterator
    getter :current, :colors

    def initialize(@current = 0, @colors = [:red, :green, :yellow, :blue, :magenta, :cyan]); end

    # Fetch next color
    def next
      if @colors[@current]?.nil?
        @current = 0
      end
      sym = @colors[@current]
      @current += 1
      sym
    end
  end
end