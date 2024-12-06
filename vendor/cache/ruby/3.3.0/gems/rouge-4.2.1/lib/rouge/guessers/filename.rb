# frozen_string_literal: true

module Rouge
  module Guessers
    class Filename < Guesser
      attr_reader :fname
      def initialize(filename)
        @filename = filename
      end

      # returns a list of lexers that match the given filename with
      # equal specificity (i.e. number of wildcards in the pattern).
      # This helps disambiguate between, e.g. the Nginx lexer, which
      # matches `nginx.conf`, and the Conf lexer, which matches `*.conf`.
      # In this case, nginx will win because the pattern has no wildcards,
      # while `*.conf` has one.
      def filter(lexers)
        mapping = {}
        lexers.each do |lexer|
          mapping[lexer.name] = lexer.filenames || []
        end

        GlobMapping.new(mapping, @filename).filter(lexers)
      end
    end
  end
end
