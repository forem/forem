# frozen_string_literal: true

module RubyNext
  module Language
    module Rewriters
      using RubyNext

      # Separate pattern matching rewriter for Ruby 2.7 to
      # transpile only case...in  with a find pattern
      class FindPattern < PatternMatching
        NAME = "pattern-matching-find-pattern"
        SYNTAX_PROBE = "case 0; in [*,0,*]; true; else; 1; end"
        MIN_SUPPORTED_VERSION = Gem::Version.new("3.0.0")

        def on_case_match(node)
          @has_find_pattern = false
          process_regular_node(node).then do |new_node|
            return new_node unless has_find_pattern
            super(node)
          end
        end

        def on_match_pattern(node)
          @has_find_pattern = false
          process_regular_node(node).then do |new_node|
            return new_node unless has_find_pattern
            super(node)
          end
        end

        def on_find_pattern(node)
          @has_find_pattern = true
          super(node)
        end

        private

        attr_reader :has_find_pattern
      end
    end
  end
end
