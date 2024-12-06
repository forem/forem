# frozen_string_literal: true

module Rouge
  module Guessers
    class Mimetype < Guesser
      attr_reader :mimetype
      def initialize(mimetype)
        @mimetype = mimetype
      end

      def filter(lexers)
        lexers.select { |lexer| lexer.mimetypes.include? @mimetype }
      end
    end
  end
end
