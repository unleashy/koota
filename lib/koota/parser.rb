# frozen_string_literal: true

require 'koota/error'
require 'koota/string_stream'

module Koota
  # Parses Koota patterns.
  class Parser
    # This class is raised on syntax errors.
    class Error < Koota::Error; end

    def call(input)
      @input = StringStream.new(input)

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
