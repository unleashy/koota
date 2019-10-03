# frozen_string_literal: true

require 'koota/compiler'
require 'koota/vm'

RSpec.describe Koota::Compiler do
  let(:compiler) { described_class.new }

  # helper opcode defs
  let(:op_halt) { Koota::VM::Opcodes::HALT }
  let(:op_jump) { Koota::VM::Opcodes::JUMP }
  let(:op_put)  { Koota::VM::Opcodes::PUT }
  let(:op_pick) { Koota::VM::Opcodes::PICK }
  let(:op_call) { Koota::VM::Opcodes::CALL }
  let(:op_ret)  { Koota::VM::Opcodes::RET }

  describe '#call' do
    context 'with an empty array' do
      it 'raises an error' do
        expect { compiler.call([]) }.to raise_error(ArgumentError, 'invalid AST')
      end
    end

    it 'compiles single atoms', :aggregate_failures do
      expect(compiler.call([:atom, 'a'])).to eq([op_put, 'a'.ord, op_halt])
      expect(compiler.call([:raw, 'a'])).to eq([op_put, 'a'.ord, op_halt])
    end

    it 'compiles multiple atoms into many parts', :aggregate_failures do
      expect(compiler.call([:atom, 'ab'])).to eq([op_put, 'a'.ord, op_put, 'b'.ord, op_halt])
      expect(compiler.call([:raw, 'ab'])).to eq([op_put, 'a'.ord, op_put, 'b'.ord, op_halt])
    end

    it 'compiles atoms using UTF-8', :aggregate_failures do
      originals = ['o', 'Δ', 'エ', '😎']
      unpackeds = originals.map(&:bytes)

      originals.zip(unpackeds) do |original, unpacked|
        expect(compiler.call([:atom, original])).to eq([op_put, *unpacked, op_halt])
      end
    end

    it 'processes references inside atoms' do
      code = [
        op_put, 'a'.ord,
        op_call, 0, 8, # Subroutine 1
        op_put, 'c'.ord,
        op_halt,
        # Subroutine 1 starts here
        op_put, 'b'.ord,
        op_ret
      ]

      expect(compiler.call([:atom, 'aBc'], { B: [:atom, 'b'] })).to eq(code)
    end

    it 'processes nested references' do
      code = [
        op_put, 'a'.ord,
        op_call, 0, 8, # Subroutine 1
        op_put, 'c'.ord,
        op_halt,
        # Subroutine 1 starts here
        op_call, 0, 12, # Subroutine 2
        op_ret,
        # Subroutine 2 starts here
        op_put, 'b'.ord,
        op_ret
      ]

      expect(compiler.call([:atom, 'aBc'], { B: [:atom, 'X'], X: [:atom, 'b'] })).to eq(code)
    end

    it 'ignores unreferenced' do
      code = [
        op_put, 'a'.ord,
        op_call, 0, 8, # Subroutine 1
        op_put, 'c'.ord,
        op_halt,
        # Subroutine 1 starts here
        op_put, 'b'.ord,
        op_ret
      ]

      expect(compiler.call([:atom, 'aBc'], { B: [:atom, 'b'], X: [:atom, 'x'] })).to eq(code)
    end

    it 'compiles pattern' do
      expect(compiler.call([:pattern, [:atom, 'a'], [:atom, 'b']])).to eq([
        op_put, 'a'.ord,
        op_put, 'b'.ord,
        op_halt
      ])
    end

    it 'compiles choice' do
      code = [
        op_pick, 0, 16, # Links to pick list at offset 16
        op_put, 'a'.ord,
        op_jump, 0, 15,
        op_put, 'b'.ord,
        op_jump, 0, 15,
        op_put, 'c'.ord,
        op_halt,
        # Pick list starts here, offset 16
        0, 3, # 3 items long
        0, 3, # points to put 'a'
        0, 8, # points to put 'b'
        0, 13 # points to put 'c'
      ]

      expect(compiler.call([:choice, [:atom, 'a'], [:atom, 'b'], [:atom, 'c']])).to eq(code)
    end

    it 'compiles choice mixed with references' do
      code = [
        op_pick, 0, 15, # Links to pick list at offset 15
        op_put, 'a'.ord,
        op_jump, 0, 11,
        op_call, 0, 12, # Links to subroutine 1 at offset 12
        op_halt,
        # Subroutine 1 starts here at offset 12
        op_put, 'b'.ord,
        op_ret,
        # Pick list starts here at offset 15
        0, 2, # 2 items long
        0, 3, # points to put 'a'
        0, 8, # points to call 0, 12
      ]

      expect(compiler.call([:choice, [:atom, 'a'], [:atom, 'B']], { B: [:atom, 'b'] })).to eq(code)
    end

    it 'compiles multiple pick lists' do
      ast = [
        :pattern,
        [
          :choice,
          [:atom, 'p'],
          [:atom, 'b']
        ],
        [
          :choice,
          [:atom, 'a'],
          [:atom, 'e']
        ]
      ]

      code = [
        op_pick, 0, 21, # Pick list 1
        op_put, 'p'.ord,
        op_jump, 0, 10,
        op_put, 'b'.ord,
        op_pick, 0, 27, # Pick list 2
        op_put, 'a'.ord,
        op_jump, 0, 20,
        op_put, 'e'.ord,
        op_halt,
        # Pick list 1 starts here
        0, 2,
        0, 3,
        0, 8,
        # Pick list 2 starts here
        0, 2,
        0, 13,
        0, 18
      ]

      expect(compiler.call(ast)).to eq(code)
    end

    it 'compiles maybe down to pick' do
      code = [
        op_pick, 0, 8, # Links to pick list
        op_put, 'b'.ord,
        op_put, 'a'.ord,
        op_halt,
        # Pick list starts here
        0, 2,
        0, 3, # Links to put 'b'
        0, 7, # Links to halt
      ]

      expect(compiler.call([:maybe, [:pattern, [:atom, 'b'], [:atom, 'a']]])).to eq(code)
    end
  end
end
