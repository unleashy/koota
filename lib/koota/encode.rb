# frozen_string_literal: true

module Koota
  module Encode
    module_function

    def short(num)
      raise ArgumentError, 'number is too large' if num > 0xFFFF

      [(num & 0xFF00) >> 8, num & 0x00FF]
    end

    def utf8(char)
      raise ArgumentError, 'empty string given' if char.empty?
      raise ArgumentError, 'expected one-char string' unless char.length == 1

      char.bytes
    end
  end
end
