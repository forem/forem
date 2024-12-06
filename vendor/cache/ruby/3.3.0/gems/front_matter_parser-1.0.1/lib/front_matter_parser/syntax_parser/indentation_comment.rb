# frozen_string_literal: true

module FrontMatterParser
  module SyntaxParser
    # Parser for syntaxes which use comments ended by indentation
    class IndentationComment
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
      def build_regexp(delimiter)
        /
        \A
        [[:space:]]*
        (?<multiline_comment_indentation>^[[:blank:]]*)
        #{delimiter}
        [[:space:]]*
        ---
        (?<front_matter>.*?)
        ---
        [[:blank:]]*$[\n\r]
        (?<content>.*)
        \z
        /mx
      end
      # rubocop:enable Metrics/MethodLength
    end
  end
end
