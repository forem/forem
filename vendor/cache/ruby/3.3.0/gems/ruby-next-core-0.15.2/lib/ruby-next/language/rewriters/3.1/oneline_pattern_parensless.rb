# frozen_string_literal: true

module RubyNext
  module Language
    module Rewriters
      using RubyNext

      # Allow omitting parentheses around patterns in `=>` and `in`
      class OnelinePatternParensless < Base
        NAME = "pattern-matching-oneline-parensless"
        SYNTAX_PROBE = "[1, 2] => a, b"
        MIN_SUPPORTED_VERSION = Gem::Version.new("3.1.0")

        def on_match_pattern(node)
          _, pattern = *node.children

          # When no parens, children boundaries are the same as the whole pattern
          if (
            pattern.type == :array_pattern ||
            pattern.type == :hash_pattern
          ) &&
              pattern.children.any? &&
              pattern.loc.column == pattern.children.first.loc.column &&
              pattern.loc.last_column == pattern.children.last.loc.last_column

            context.track! self

            left_p, right_p = pattern.type == :array_pattern ? %w([ ]) : %w[{ }]

            insert_before(pattern.loc.expression, left_p)
            insert_after(pattern.loc.expression, right_p)
          else
            super(node)
          end
        end

        alias on_match_pattern_p on_match_pattern
      end
    end
  end
end
