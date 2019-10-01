# frozen_string_literal: true

require 'koota/vm'

RSpec.describe Koota::VM do
  let(:vm) { described_class.new }

  # helper opcode defs
  let(:op_halt) { Koota::VM::Opcodes::HALT }
  let(:op_jump) { Koota::VM::Opcodes::JUMP }
  let(:op_put)  { Koota::VM::Opcodes::PUT }

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
  end
end
