# frozen_string_literal: true

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
          offset = decode_short(memory, offset)

        when Opcodes::PUT
          decoded, advance = decode_utf8(memory, offset)
          output << decoded
          offset += advance

        else break
        end
      end

      output
    end

    private

    def decode_short(memory, offset)
      (memory[offset] << 8) | memory[offset + 1]
    end

    def decode_utf8(memory, offset)
      # Determine the length of the UTF-8 sequence using the first byte, as per
      # the table here: https://en.wikipedia.org/wiki/UTF-8#Description
      first = memory[offset]
      seq_length = if first <= 0b0111_1111
                     1
                   elsif first <= 0b1101_1111
                     2
                   elsif first <= 0b1110_1111
                     3
                   else
                     4
                   end

      # With the length of the UTF-8 sequence determined, we can transform the
      # sequence to a string with #pack interpreting each number as an 8-bit
      # unsigned number and #force_encoding using UTF-8, completing the
      # decoding.
      decoded = memory[offset, seq_length].pack('C*').force_encoding('UTF-8')

      # Return also the sequence length so the VM knows how much to advance the
      # offset.
      [decoded, seq_length]
    end
  end
end
