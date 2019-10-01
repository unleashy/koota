# frozen_string_literal: true

require 'koota/decode'

module Koota
  class VM
    module Opcodes
      HALT = 0x00
      JUMP = 0x01
      PUT  = 0x02
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

        else break
        end
      end

      output
    end
  end
end
