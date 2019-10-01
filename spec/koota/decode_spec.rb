# frozen_string_literal: true

require 'koota/decode'

RSpec.describe Koota::Decode do
  let(:decode) { described_class }

  describe '.short' do
    it 'decodes short integers', :aggregate_failures do
      expect(decode.short([0x00, 0xFF])).to eq(0x00FF)
      expect(decode.short([0x01, 0x00])).to eq(0x0100)
      expect(decode.short([0xFF, 0xFF])).to eq(0xFFFF)
    end
  end

  describe '.utf8' do
    it 'decodes UTF-8 characters', :aggregate_failures do
      originals = ['*', 'α', '人', '🍞']
      unpackeds = originals.map(&:bytes)

      originals.zip(unpackeds) do |original, unpacked|
        expect(decode.utf8(unpacked)).to eq([original, unpacked.length])
      end
    end
  end
end
