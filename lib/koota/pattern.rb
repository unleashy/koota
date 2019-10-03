# frozen_string_literal: true

module Koota
  class Pattern
    attr_reader :string, :refs

    def initialize(pattern, refs = {})
      @string = pattern
      @refs   = refs
    end
  end
end
