# frozen_string_literal: true

require 'koota/decode'

module Koota
  class VM
    module Opcodes
      HALT = 0x00
      JUMP = 0x01
      PUT  = 0x02
      PICK = 0x03
      CALL = 0x04
      RET  = 0x05
    end

    CALL_STACK_MAX = 256

    def initialize(random: Random.new)
      @random = random
    end

    def call(memory)
      output = ''.dup
      call_stack = []
      offset = 0

      while offset < memory.length
        op = memory[offset]
        offset += 1

        case op
        when Opcodes::HALT then break
        when Opcodes::JUMP
          offset = Decode.short(memory, offset)

        when Opcodes::PUT
          decoded, advance = Decode.utf8(memory, offset)
          output << decoded
          offset += advance

        when Opcodes::PICK
          list_pointer = Decode.short(memory, offset)
          list_length  = Decode.short(memory, list_pointer)

          # Jump to the chosen offset.
          # Multiply the rand by two because each offset has two bytes, and the
          # list length represents the length of each two-byte block.
          # Also, the offset starts at 1 to skip the list length.
          offset = Decode.short(memory, list_pointer + 2 * @random.rand(1..list_length))

        when Opcodes::CALL
          break if call_stack.length >= CALL_STACK_MAX
          routine_pointer = Decode.short(memory, offset)
          call_stack.push(offset + 2) # opcode after the routine pointer
          offset = routine_pointer

        when Opcodes::RET
          offset = call_stack.pop
          break if offset.nil?

        else break
        end
      end

      output
    end
  end
end
