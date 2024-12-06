# frozen_string_literal: true

module FrontMatterParser
  module SyntaxParser
    # Parser for syntaxes which each comment is for a single line
    class SingleLineComment
      extend Factorizable

      # @!attribute [r] regexp
      # A regexp that returns two groups: front_matter (with comment delimiter
      # in it) and content
      attr_reader :regexp

      def initialize
        @regexp = build_regexp(*self.class.delimiters)
      end

      # @see SyntaxParser
      def call(string)
        match = string.match(regexp)
        if match
          front_matter = self.class.remove_delimiter(match[:front_matter])
          {
            front_matter: front_matter,
            content: match[:content]
          }
        else
          match
        end
      end

      # @see Factorizable
      # :nocov:
      def self.delimiters
        raise NotImplementedError
      end

      # @!visibility private
      def self.remove_delimiter(front_matter)
        delimiter = delimiters.first
        front_matter.gsub(/^[\s\t]*#{delimiter}/, '')
      end

      private

      # rubocop:disable Metrics/MethodLength
      def build_regexp(delimiter)
        /
        \A
        [[:space:]]*
        #{delimiter}[[:blank:]]*
        ---
        (?<front_matter>.*?)
        ^[[:blank:]]*#{delimiter}[[:blank:]]*
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
