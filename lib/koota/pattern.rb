# frozen_string_literal: true

module Koota
  class Pattern
    attr_reader :pattern, :refs

    def initialize(pattern, refs = {})
      @pattern = pattern
      @refs    = refs
    end
  end
end
