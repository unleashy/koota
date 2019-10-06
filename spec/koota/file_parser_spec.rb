# frozen_string_literal: true

require 'koota/file_parser'

RSpec.describe Koota::FileParser do
  let(:parser) { described_class.new }

  describe 'call' do
    context 'with an empty string' do
      it 'raises FileParser::Error' do
        expect { parser.call('') }.to raise_error(Koota::FileParser::Error, 'missing root pattern')
      end
    end

    context 'with only comments and whitespace' do
      it 'raises FileParser::Error' do
        input = <<~INPUT
          # comment comment
          #

          # bread
                 # wow

        INPUT

        expect { parser.call(input) }.to raise_error(Koota::FileParser::Error, 'missing root pattern')
      end
    end

    context 'with a root pattern' do
      it 'succeeds' do
        result = parser.call('abc')

        expect(result).to eq(Koota::Pattern.new('abc'))
      end
    end

    context 'with more than one root pattern' do
      it 'raises FileParser::Error' do
        expect { parser.call("hello\nworld") }.to raise_error(Koota::FileParser::Error, 'more than one root pattern')
      end
    end

    context 'with subpatterns' do
      it 'succeeds' do
        result = parser.call(<<~INPUT)
          C = p/t/k
          C
        INPUT

        expect(result).to eq(Koota::Pattern.new('C', C: Koota::Pattern.new('p/t/k')))
      end

      it 'resolves nested references' do
        result = parser.call(<<~INPUT)
          N = m/n
          C = p/t/k/N
          C
        INPUT

        expected = Koota::Pattern.new(
          'C',
          C: Koota::Pattern.new('p/t/k/N', N: Koota::Pattern.new('m/n'))
        )

        expect(result).to eq(expected)
      end

      it 'ignores forward references' do
        result = parser.call(<<~INPUT)
          C = p/t/k/N
          N = m/n
          C
        INPUT

        expect(result).to eq(Koota::Pattern.new('C', C: Koota::Pattern.new('p/t/k/N')))
      end
    end
  end
end
