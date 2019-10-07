# frozen_string_literal: true

require 'koota/parser'

RSpec.describe Koota::Parser do
  let(:parser) { described_class.new }

  describe '#call' do
    INPUTS = [
      # input, result
      ['',  Koota::Parser::Error.new('unexpected end of input')],
      ['a', [:pattern, [:atom, 'a']]],
      ['abc def', [:pattern, [:atom, 'abc def']]],
      ['ab"cd"', [:pattern, [:atom, 'ab'], [:raw, 'cd']]],
      ['"a(b)c[d]e/f"', [:pattern, [:raw, 'a(b)c[d]e/f']]],
      ['a/b', [:pattern, [:choice, [:atom, 'a'], [:atom, 'b']]]],
      ['"a/b"/"b/c"', [:pattern, [:choice, [:raw, 'a/b'], [:raw, 'b/c']]]],
      ['(a)', [:pattern, [:maybe, [:pattern, [:atom, 'a']]]]],
      ['(abc', Koota::Parser::Error.new('unclosed parenthesis')],
      ['aa)', Koota::Parser::Error.new('unexpected ")"')],
      ['[a]', [:pattern, [:pattern, [:atom, 'a']]]],
      ['[abc', Koota::Parser::Error.new('unclosed brackets')],
      ['aa]', Koota::Parser::Error.new('unexpected "]"')],
      [
        '(a/b)[c/d]',
        [
          :pattern,
          [:maybe, [:pattern, [:choice, [:atom, 'a'], [:atom, 'b']]]],
          [:pattern, [:choice, [:atom, 'c'], [:atom, 'd']]]
        ]
      ],
      [
        '(a(b))',
        [
          :pattern,
          [
            :maybe,
            [
              :pattern,
              [:atom, 'a'],
              [:maybe, [:pattern, [:atom, 'b']]]
            ]
          ]
        ]
      ],
      ['[a[b]]', [:pattern, [:pattern, [:atom, 'a'], [:pattern, [:atom, 'b']]]]],
      ['a/(b)', Koota::Parser::Error.new('unexpected "("')],
      ['a/b(c)', [:pattern, [:choice, [:atom, 'a'], [:atom, 'b']], [:maybe, [:pattern, [:atom, 'c']]]]],
      ['()', Koota::Parser::Error.new('unexpected ")"')],
      ['[]', Koota::Parser::Error.new('unexpected "]"')]
    ].freeze

    INPUTS.each do |input, result|
      context "with input like #{input.inspect}" do
        if result.is_a?(Exception)
          it "raises an error with message like #{result.message.inspect}" do
            expect { parser.call(input) }.to raise_error(result.class, result.message)
          end
        else
          it "returns an AST like #{result.inspect}" do
            expect(parser.call(input)).to eq(result)
          end
        end
      end
    end
  end
end
