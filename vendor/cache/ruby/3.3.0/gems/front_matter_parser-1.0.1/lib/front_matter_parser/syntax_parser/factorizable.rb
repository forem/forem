# frozen_string_literal: true

module FrontMatterParser
  module SyntaxParser
    # This is just a helper to allow creating syntax parsers with a more terse
    # syntax, without the need of explicitly creating descendant classes for the
    # most general cases. See {SyntaxParser} for examples in use.
    module Factorizable
      # @param delimiters [String] Splat arguments with all comment delimiters
      # used by the parser
      #
      # @return [Object] A base class of self with a `delimiters` class method
      # added which returns an array with given comment delimiters
      def [](*delimiters)
        delimiters = delimiters.map { |delimiter| Regexp.escape(delimiter) }
        create_base_class(delimiters)
      end

      private

      def create_base_class(delimiters)
        parser = Class.new(self)
        parser.define_singleton_method(:delimiters) do
          delimiters
        end
        parser
      end
    end
  end
end
