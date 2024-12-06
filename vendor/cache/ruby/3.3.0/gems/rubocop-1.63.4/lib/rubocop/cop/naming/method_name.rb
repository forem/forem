# frozen_string_literal: true

module RuboCop
  module Cop
    module Naming
      # Makes sure that all methods use the configured style,
      # snake_case or camelCase, for their names.
      #
      # This cop has `AllowedPatterns` configuration option.
      #
      #   Naming/MethodName:
      #     AllowedPatterns:
      #       - '\AonSelectionBulkChange\z'
      #       - '\AonSelectionCleared\z'
      #
      # Method names matching patterns are always allowed.
      #
      # @example EnforcedStyle: snake_case (default)
      #   # bad
      #   def fooBar; end
      #
      #   # good
      #   def foo_bar; end
      #
      # @example EnforcedStyle: camelCase
      #   # bad
      #   def foo_bar; end
      #
      #   # good
      #   def fooBar; end
      class MethodName < Base
        include ConfigurableNaming
        include AllowedPattern
        include RangeHelp

        MSG = 'Use %<style>s for method names.'

        # @!method sym_name(node)
        def_node_matcher :sym_name, '(sym $_name)'

        # @!method str_name(node)
        def_node_matcher :str_name, '(str $_name)'

        def on_send(node)
          return unless (attrs = node.attribute_accessor?)

          attrs.last.each do |name_item|
            name = attr_name(name_item)
            next if !name || matches_allowed_pattern?(name)

            check_name(node, name, range_position(node))
          end
        end

        def on_def(node)
          return if node.operator_method? || matches_allowed_pattern?(node.method_name)

          check_name(node, node.method_name, node.loc.name)
        end
        alias on_defs on_def

        private

        def attr_name(name_item)
          sym_name(name_item) || str_name(name_item)
        end

        def range_position(node)
          selector_end_pos = node.loc.selector.end_pos + 1
          expr_end_pos = node.source_range.end_pos

          range_between(selector_end_pos, expr_end_pos)
        end

        def message(style)
          format(MSG, style: style)
        end
      end
    end
  end
end
