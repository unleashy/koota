# frozen_string_literal: true

RSpec.describe Koota::Generator do
  let(:nasals)     { Koota::Pattern.new('m/n') }
  let(:consonants) { Koota::Pattern.new('p/t/k/N', N: nasals) }
  let(:vowels)     { Koota::Pattern.new('a/i/u') }
  let(:pattern)    { Koota::Pattern.new('(C)V', C: consonants, V: vowels) }
  let(:generator)  { described_class.new }

  describe '#call' do
    it 'generates words', :aggregate_failures do
      result = generator.call(pattern)

      expect(result).to be_an(Array)
      expect(result.length).to be <= 100
      expect(result).to all(match(/\A[ptkmn]?[aiu]\z/))
    end

    it 'takes all the cool options' do
      random = instance_double('Random')
      allow(random).to receive(:rand).and_return(1)

      vm = Koota::VM.new(random: random)
      generator = Koota::Generator.new(vm: vm)

      result = generator.call(
        pattern,
        words: 20,
        syllables: 4,
        syllable_separator: '.',
        duplicates: true
      )

      expect(result).to be_an(Array)
      expect(result.length).to eq(20)
      expect(result).to all(match(/\A(?:[ptkmn]?[aiu]\.){3}[ptkmn]?[aiu]\z/))
      expect(result.uniq.length).to be(1) # aka everything is the same
    end
  end
end
