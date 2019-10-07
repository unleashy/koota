# frozen_string_literal: true

module Koota
  # This is a simple class holding a pattern string and its references hash.
  class Pattern
    attr_reader :string, :refs

    def initialize(pattern, refs = {})
      @string = pattern
      @refs   = refs
    end

    def ==(other)
      other.class == self.class && other.string == string && other.refs == refs
    end
  end
end
