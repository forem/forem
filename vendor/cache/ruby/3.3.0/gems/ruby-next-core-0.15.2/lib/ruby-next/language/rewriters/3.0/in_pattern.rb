# frozen_string_literal: true

module RubyNext
  module Language
    module Rewriters
      using RubyNext

      # Separate pattern matching rewriter for Ruby 2.7 to
      # transpile only `in` patterns
      class InPattern < PatternMatching
        NAME = "pattern-matching-in"
        SYNTAX_PROBE = "1 in 2"
        MIN_SUPPORTED_VERSION = Gem::Version.new("3.0.0")

        # Make case-match no-op
        def on_case_match(node)
          process_regular_node(node)
        end
      end
    end
  end
end
