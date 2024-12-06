# frozen_string_literal: true

module RubyNext
  module Language
    module Rewriters
      using RubyNext

      # Separate pattern matching rewriter for Ruby <3.2 to
      # transpile patterns with variable (instance, class, global) binding
      class BindVarsPattern < PatternMatching
        NAME = "pattern-matching-find-pattern"
        SYNTAX_PROBE = "case 0; in @a; true; else; 1; end"
        MIN_SUPPORTED_VERSION = Gem::Version.new(RubyNext::NEXT_VERSION)

        def on_case_match(node)
          @has_vars_pattern = false
          process_regular_node(node).then do |new_node|
            return new_node unless has_vars_pattern
            super(node)
          end
        end

        def on_match_pattern(node)
          @has_vars_pattern = false
          process_regular_node(node).then do |new_node|
            return new_node unless has_vars_pattern
            super(node)
          end
        end

        def on_match_pattern_p(node)
          @has_vars_pattern = false
          process_regular_node(node).then do |new_node|
            return new_node unless has_vars_pattern
            super(node)
          end
        end

        def on_match_var(node)
          @has_vars_pattern = true if node.children[0].is_a?(::Parser::AST::Node)
          super(node)
        end

        private

        attr_reader :has_vars_pattern
      end
    end
  end
end
