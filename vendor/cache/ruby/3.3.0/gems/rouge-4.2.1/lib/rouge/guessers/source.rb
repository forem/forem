# frozen_string_literal: true

module Rouge
  module Guessers
    class Source < Guesser
      include Util

      attr_reader :source
      def initialize(source)
        @source = source
      end

      def filter(lexers)
        # don't bother reading the input if
        # we've already filtered to 1
        return lexers if lexers.size == 1

        source_text = get_source(@source)

        Lexer.assert_utf8!(source_text)

        source_text = TextAnalyzer.new(source_text)

        collect_best(lexers) do |lexer|
          next unless lexer.detectable?
          lexer.detect?(source_text) ? 1 : nil
        end
      end
    end
  end
end
