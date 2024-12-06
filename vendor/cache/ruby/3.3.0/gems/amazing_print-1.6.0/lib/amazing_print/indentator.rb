# frozen_string_literal: true

module AmazingPrint
  class Indentator
    attr_reader :shift_width, :indentation

    def initialize(indentation)
      @indentation = indentation
      @shift_width = indentation.freeze
    end

    def indent
      @indentation += shift_width
      yield
    ensure
      @indentation -= shift_width
    end
  end
end
