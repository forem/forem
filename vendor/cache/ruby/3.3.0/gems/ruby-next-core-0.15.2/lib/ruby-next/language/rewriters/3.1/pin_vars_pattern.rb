# frozen_string_literal: true

module RubyNext
  module Language
    module Rewriters
      using RubyNext

      # Separate pattern matching rewriter for Ruby 2.7 and 3.0 to
      # transpile only ^(ivar|cvar|gvar)
      class PinVarsPattern < PatternMatching
        NAME = "pattern-matching-pin-vars"
        SYNTAX_PROBE = "@a = 0; case 0; in ^@a; true; end"
        MIN_SUPPORTED_VERSION = Gem::Version.new("3.1.0")

        def on_case_match(node)
          @has_pin_vars = false
          process_regular_node(node).then do |new_node|
            return new_node unless has_pin_vars
            super(node)
          end
        end

        def on_match_pattern(node)
          @has_pin_vars = false
          process_regular_node(node).then do |new_node|
            return new_node unless has_pin_vars
            super(node)
          end
        end

        def on_match_pattern_p(node)
          @has_pin_vars = false
          process_regular_node(node).then do |new_node|
            return new_node unless has_pin_vars
            super(node)
          end
        end

        def on_pin(node)
          @has_pin_vars = node.children.first.type != :lvar
          super(node)
        end

        private

        attr_reader :has_pin_vars
      end
    end
  end
end
