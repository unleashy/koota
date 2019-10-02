# frozen_string_literal: true

module Koota
  # Parses Koota patterns.
  class Parser
    # This class is raised on syntax errors.
    class Error < Koota::Error; end

    # @api private
    class Input
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

    private_constant :Input

    def call(input)
      @input = Input.new(input)

      pattern.tap do
        error!("unexpected #{@input.get.inspect}") unless @input.empty?
      end
    end

    private

    def pattern
      [:pattern, group].tap do |result|
        result << group until @input.empty? || @input.match?(')', ']')
      end
    end

    def group
      if @input.skip('(')
        [:maybe, pattern].tap { error!('unclosed parenthesis') unless @input.skip(')') }
      elsif @input.skip('[')
        pattern.tap { error!('unclosed brackets') unless @input.skip(']') }
      else
        choice
      end
    end

    def choice
      result = [atom].tap do |r|
        r << atom while @input.skip('/')
      end

      result.length == 1 ? result[0] : [:choice, *result]
    end

    def atom
      if @input.empty?
        error!('unexpected end of input')
      elsif @input.skip('"')
        [:raw, @input.get_until('"')].tap do
          @input.get # skip the end quote
        end
      elsif (result = @input.get_until('[', ']', '(', ')', '"', '/'))
        [:atom, result]
      else
        error!("unexpected #{@input.get.inspect}")
      end
    end

    def error!(message)
      raise Error, message
    end
  end
end
