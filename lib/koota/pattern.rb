# frozen_string_literal: true

module Koota
  class Pattern
    attr_reader :string, :refs

    def initialize(pattern, refs = {})
      @string = pattern
      @refs   = refs
    end

    def ==(o)
      o.class == self.class && o.string == string && o.refs == refs
    end
  end
end
