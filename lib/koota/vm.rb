# frozen_string_literal: true

require 'koota/decode'

module Koota
  class VM
    module Opcodes
      HALT = 0x00
      JUMP = 0x01
      PUT  = 0x02
      PICK = 0x03
    end

    def initialize(random: Random.new)
      @random = random
    end

    def call(memory)
      output = ''.dup
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

        else break
        end
      end

      output
    end
  end
end
