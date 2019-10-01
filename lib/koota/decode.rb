# frozen_string_literal: true

module Koota
  # Various helper decoding methods.
  # @api private
  module Decode
    module_function

    def short(array, offset = 0)
      (array[offset] << 8) | array[offset + 1]
    end

    def utf8(array, offset = 0)
      # Determine the length of the UTF-8 sequence using the first byte, as per
      # the table here: https://en.wikipedia.org/wiki/UTF-8#Description
      first = array[offset]
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
      decoded = array[offset, seq_length].pack('C*').force_encoding('UTF-8')

      # Return also the sequence length so the user knows how long it was.
      [decoded, seq_length]
    end
  end
end
