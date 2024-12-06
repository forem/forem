# frozen_string_literal: true

module Solargraph
  class SourceMap
    # The result of a completion request containing the pins that describe
    # completion options and the range to be replaced.
    #
    class Completion
      # @return [Array<Solargraph::Pin::Base>]
      attr_reader :pins

      # @return [Solargraph::Range]
      attr_reader :range

      # @param pins [Array<Solargraph::Pin::Base>]
      # @param range [Solargraph::Range]
      def initialize pins, range
        @pins = pins
        @range = range
      end
    end
  end
end
