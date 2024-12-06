# frozen_string_literal: true

module FrontMatterParser
  module SyntaxParser
    # Parser for syntaxes which use end and finish comment delimiters
    class MultiLineComment
      extend Factorizable

      # @!attribute [r] regexp
      # A regexp that returns two groups: front_matter and content
      attr_reader :regexp

      def initialize
        @regexp = build_regexp(*self.class.delimiters)
      end

      # @see SyntaxParser
      def call(string)
        string.match(regexp)
      end

      # @see Factorizable
      # :nocov:
      def self.delimiters
        raise NotImplementedError
      end

      private

      # rubocop:disable Metrics/MethodLength
      def build_regexp(start_delimiter, end_delimiter)
        /
        \A
        [[:space:]]*
        #{start_delimiter}
        [[:space:]]*
        ---
        (?<front_matter>.*?)
        ---
        [[:space:]]*
        #{end_delimiter}
        [[:blank:]]*$[\n\r]
        (?<content>.*)
        \z
        /mx
      end
      # rubocop:enable Metrics/MethodLength
    end
  end
end
