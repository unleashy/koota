# frozen_string_literal: true

module Koota
  # @api private
  class StringStream
    def initialize(input)
      @input = input
      @pos   = 0
    end

    def empty?
      @pos >= @input.length
    end

    def peek
      @input[@pos]
    end

    def get
      peek.tap { @pos += 1 }
    end

    def match?(*args)
      args.index(peek)
    end

    def skip(*args)
      if (index = match?(*args))
        @pos += args[index].length
      end
    end

    def get_until(*args)
      start = @pos

      # Advance the position until the stopping point is found.
      @pos += 1 until empty? || match?(*args)

      start == @pos ? nil : @input[start, @pos - start]
    end
  end
end
