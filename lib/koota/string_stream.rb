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
      peek.tap { advance }
    end

    def advance(steps = 1)
      @pos += steps
    end

    def match?(*args)
      args.index(peek)
    end

    def skip(*args)
      index = match?(*args)
      return unless index

      advance(args[index].length)
    end

    def skip_until(*args)
      advance until empty? || match?(*args)
    end

    def get_until(*args)
      start = @pos

      skip_until(*args)

      start == @pos ? nil : @input[start, @pos - start]
    end
  end
end
