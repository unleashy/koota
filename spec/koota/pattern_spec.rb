# frozen_string_literal: true

RSpec.describe Koota::Pattern do
  let(:subpattern) { described_class.new('t/d') }
  let(:pattern)    { described_class.new('a/b/c/D', D: subpattern) }

  describe '#string' do
    it 'returns the raw string of the pattern' do
      expect(pattern.string).to eq('a/b/c/D')
    end
  end

  describe '#refs' do
    it "returns the pattern's references" do
      expect(pattern.refs).to eq(D: subpattern)
    end
  end
end
