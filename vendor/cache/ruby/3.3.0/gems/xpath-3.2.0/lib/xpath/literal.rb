# frozen_string_literal: true

module XPath
  class Literal
    attr_reader :value
    def initialize(value)
      @value = value
    end
  end
end
