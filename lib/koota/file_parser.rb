# frozen_string_literal: true

require 'koota/error'
require 'koota/pattern'

module Koota
  # This class parses .koota input files; mainly used by {Koota::CLI}.
  class FileParser
    class Error < Koota::Error; end

    def call(input)
      refs = {}
      root = process_input(input) do |subpat_key, subpat_value|
        subpat_refs = find_refs(subpat_value, refs)
        refs[subpat_key] = Koota::Pattern.new(subpat_value, subpat_refs)
      end

      Koota::Pattern.new(root, find_refs(root, refs))
    end

    private

    def find_refs(pattern, refs)
      refs.select { |(key, _)| pattern.include?(key.to_s) }
    end

    def process_input(input, &block)
      # Splits the input into lines, then ignores comments, blank lines, and
      # spaces between '=', while at the same time passing subpatterns for
      # processing by the block. Gets angry if no root pattern or more than one
      # root pattern.
      rest = input.split("\n").reject do |line|
        stripped = line.strip
        next true if stripped.empty? || stripped.start_with?('#')

        if (m = stripped.match(/^(.+?)=([^#\n]+)(?:#.+$)?/))
          block.call(m[1].strip.to_sym, m[2].strip)
          true
        end
      end.map do |line|
        line.sub(/\s*#.+$/, '')
      end

      error!('missing root pattern') if rest.empty?
      error!('more than one root pattern') if rest.length > 1

      rest[0]
    end

    def error!(msg)
      raise Error, msg
    end
  end
end
