# frozen_string_literal: true

module BetterHtml
  module Tokenizer
    class Token
      attr_reader :type, :loc

      def initialize(type:, loc:)
        @type = type
        @loc = loc
      end

      def inspect
        "t(#{type.inspect}, #{loc&.source.inspect})"
      end
    end
  end
end
