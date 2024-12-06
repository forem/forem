# frozen_string_literal: true

module RuboCop
  module Cop
    # Common functionality for cops checking single/double quotes.
    module StringLiteralsHelp
      private

      def wrong_quotes?(src_or_node)
        src = src_or_node.is_a?(RuboCop::AST::Node) ? src_or_node.source : src_or_node
        return false if src.start_with?('%', '?')

        if style == :single_quotes
          !double_quotes_required?(src)
        else
          !/" | \\[^'\\] | \#[@{$]/x.match?(src)
        end
      end
    end
  end
end
