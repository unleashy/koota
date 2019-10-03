# frozen_string_literal: true

require 'koota/encode'

RSpec.describe Koota::Encode do
  let(:encode) { described_class }

  describe '.short' do
    it 'encodes short integers', :aggregate_failures do
      expect(encode.short(0x00FF)).to eq([0x00, 0xFF])
      expect(encode.short(0x0100)).to eq([0x01, 0x00])
      expect(encode.short(0xFFFF)).to eq([0xFF, 0xFF])
    end

    context 'with a large number' do
      it 'raises ArgumentError', :aggregate_failures do
        expect { encode.short(0x10000) }.to raise_error(ArgumentError, 'number is too large')
        expect { encode.short(0xFFFFF) }.to raise_error(ArgumentError, 'number is too large')
      end
    end
  end

  describe '.utf8' do
    it 'encodes UTF-8 characters', :aggregate_failures do
      originals = ['*', 'α', '人', '🍞']
      unpackeds = originals.map(&:bytes)

      originals.zip(unpackeds) do |original, unpacked|
        expect(encode.utf8(original)).to eq(unpacked)
      end
    end

    context 'with an empty string' do
      it 'raises ArgumentError' do
        expect { encode.utf8('') }.to raise_error(ArgumentError, 'empty string given')
      end
    end

    context 'with a string longer than one character' do
      it 'raises ArgumentError', :aggregate_failures do
        expect { encode.utf8('ab') }.to raise_error(ArgumentError, 'expected one-char string')
        expect { encode.utf8('abc') }.to raise_error(ArgumentError, 'expected one-char string')
      end
    end
  end
end
