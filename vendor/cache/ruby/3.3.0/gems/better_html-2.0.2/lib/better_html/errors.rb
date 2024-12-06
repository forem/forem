# frozen_string_literal: true

require "active_support/core_ext/string/output_safety"
require "action_view"

module BetterHtml
  class InterpolatorError < RuntimeError; end
  class DontInterpolateHere < InterpolatorError; end
  class UnsafeHtmlError < InterpolatorError; end
  class HtmlError < RuntimeError; end

  class Errors < Array
    alias_method :add, :<<
  end

  class ParserError < RuntimeError
    attr_reader :position, :line, :column

    def initialize(message, position, line, column)
      super(message)
      @position = position
      @line = line
      @column = column
    end
  end
end
