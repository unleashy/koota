# frozen_string_literal: true

require 'koota/vm'

RSpec.describe Koota::VM do
  let(:vm) { described_class.new }

  # helper opcode defs
  let(:op_halt) { Koota::VM::Opcodes::HALT }
  let(:op_jump) { Koota::VM::Opcodes::JUMP }
  let(:op_put)  { Koota::VM::Opcodes::PUT }
  let(:op_pick) { Koota::VM::Opcodes::PICK }
  let(:op_call) { Koota::VM::Opcodes::CALL }
  let(:op_ret)  { Koota::VM::Opcodes::RET }

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
          0, 9  # points to put 'c'
        ]

        expect(vm.call(memory)).to eq('abc')
        expect(vm.call(memory)).to eq('bc')
        expect(vm.call(memory)).to eq('c')
      end
    end

    context 'with call and ret opcodes' do
      it 'calls plain subroutine' do
        memory = [
          op_put, 'a'.ord,
          op_call, 0, 8, # call to subroutine
          op_put, 'c'.ord,
          op_halt,
          # Subroutine starts here
          op_put, 'b'.ord,
          op_ret
        ]

        expect(vm.call(memory)).to eq('abc')
      end

      it 'calls nested subroutines' do
        memory = [
          op_put, 'a'.ord,
          op_call, 0, 8, # call to subroutine 1
          op_put, 'g'.ord,
          op_halt,
          # Subroutine 1 starts here
          op_put, 'b'.ord,
          op_call, 0, 16, # call to subroutine 2
          op_put, 'f'.ord,
          op_ret,
          # Subroutine 2 starts here
          op_put, 'c'.ord,
          op_call, 0, 24, # call to subroutine 3
          op_put, 'e'.ord,
          op_ret,
          # Subroutine 3 starts here
          op_put, 'd'.ord,
          op_ret
        ]

        expect(vm.call(memory)).to eq('abcdefg')
      end

      it 'can halt inside a subroutine' do
        memory = [
          op_put, 'a'.ord,
          op_call, 0, 8, # call to subroutine
          op_put, 'c'.ord,
          op_halt,
          # Subroutine starts here
          op_put, 'b'.ord,
          op_halt
        ]

        expect(vm.call(memory)).to eq('ab')
      end

      it 'halts on stack overflow' do
        memory = [
          op_call, 0, 0,   # calls itself!
          op_put, 'a'.ord, # should never be reached
          op_halt
        ]

        expect(vm.call(memory)).to eq('')
      end
    end

    context 'with a ret opcode' do
      it 'halts if call stack is empty' do
        expect(vm.call([op_ret, op_put, 'a'.ord, op_halt])).to eq('')
      end
    end
  end
end
