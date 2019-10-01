# frozen_string_literal: true

require 'koota/vm'

RSpec.fdescribe Koota::VM do
  let(:vm) { described_class.new }

  # helper opcode defs
  let(:op_halt) { Koota::VM::Opcodes::HALT }
  let(:op_jump) { Koota::VM::Opcodes::JUMP }
  let(:op_put)  { Koota::VM::Opcodes::PUT }
  let(:op_pick) { Koota::VM::Opcodes::PICK }

  describe '#call' do
    context 'with no bytecode' do
      it 'halts' do
        expect(vm.call([])).to eq('')
      end
    end

    context 'with unrecognised opcodes' do
      it 'halts' do
        expect(vm.call([0xFF, 0xF0, 0x55])).to eq('')
      end
    end

    context 'with a halt opcode' do
      it 'halts' do
        expect(vm.call([op_halt])).to eq('')
      end
    end

    context 'with a jump opcode' do
      it 'jumps to the given offset' do
        # jumps over the first put
        expect(vm.call([op_jump, 0, 5, op_put, 'a'.ord, op_put, 'b'.ord, op_halt])).to eq('b')
      end

      it 'halts when jumping to out of bounds' do
        expect(vm.call([op_jump, 0, 5, op_put, 'a'.ord])).to eq('')
      end
    end

    context 'with a put opcode' do
      it 'sends the argument to output' do
        expect(vm.call([op_put, 'A'.ord, op_halt])).to eq('A')
      end

      it 'decodes UTF-8 correctly', :aggregate_failures do
        originals = ['o', 'Δ', 'エ', '😎']
        unpackeds = originals.map(&:bytes)

        originals.zip(unpackeds) do |original, unpacked|
          expect(vm.call([op_put, *unpacked, op_halt])).to eq(original)
        end
      end
    end

    context 'with a pick opcode' do
      # This one needs a custom Random.
      let(:vm) do
        # This double simulates "randomness" by increasing a counter by one
        # each time its #rand method is called.
        random = double('Random')
        next_result = nil
        allow(random).to receive(:rand).with(instance_of(Range)) do |range|
          (next_result ||= range.begin).tap { next_result += 1 if next_result < range.end }
        end

        described_class.new(random: random)
      end

      it 'jumps to a random offset in the list', :aggregate_failures do
        memory = [
          op_pick, 0, 12,
          op_put, 'x'.ord, # this one is excluded!
          op_put, 'a'.ord,
          op_put, 'b'.ord,
          op_put, 'c'.ord,
          op_halt,
          # Pick list starts here, offset 12
          0, 3, # 3 items long
          0, 5, # points to put 'a'
          0, 7, # points to put 'b'
          0, 9, # points to put 'c'
        ]

        expect(vm.call(memory)).to eq('abc')
        expect(vm.call(memory)).to eq('bc')
        expect(vm.call(memory)).to eq('c')
      end
    end
  end
end
