# frozen_string_literal: true

require 'koota/parser'
require 'koota/compiler'
require 'koota/vm'

module Koota
  # This class uses a parser, compiler, and VM to generate words.
  class Generator
    DEFAULT_CALL_OPTIONS = {
      words: 100,
      syllables: 1,
      syllable_separator: '',
      duplicates: false
    }.freeze

    def initialize(parser: Koota::Parser.new, compiler: Koota::Compiler.new, vm: Koota::VM.new)
      @parser   = parser
      @compiler = compiler
      @vm       = vm
    end

    def call(pattern, options = {})
      options = DEFAULT_CALL_OPTIONS.merge(options)

      bytecode = compile(pattern)

      syllables = if options[:syllables].is_a?(Integer)
                    -> { options[:syllables] }
                  elsif options[:syllables].is_a?(Range)
                    -> { rand(options[:syllables]) }
                  else
                    type = options[:syllables].class.to_s
                    raise ArgumentError, "expected Integer or Range for syllables option, not #{type}"
                  end

      result = Array.new(options[:words]) do
        Array.new(syllables.call) { @vm.call(bytecode) }.join(options[:syllable_separator])
      end

      result.uniq! unless options[:duplicates]

      result
    end

    private

    def compile(pattern)
      @compiler.call(@parser.call(pattern.string), collect_all_refs(pattern))
    end

    def collect_all_refs(pattern)
      result = {}
      stack = [pattern.refs]

      until stack.empty?
        current = stack.pop
        current.each do |key, subpattern|
          result[key] ||= @parser.call(subpattern.string)
          stack.push(subpattern.refs)
        end
      end

      result
    end
  end
end
