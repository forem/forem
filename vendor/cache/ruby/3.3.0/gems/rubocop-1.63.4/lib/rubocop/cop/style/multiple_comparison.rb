# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks against comparing a variable with multiple items, where
      # `Array#include?`, `Set#include?` or a `case` could be used instead
      # to avoid code repetition.
      # It accepts comparisons of multiple method calls to avoid unnecessary method calls
      # by default. It can be configured by `AllowMethodComparison` option.
      #
      # @example
      #   # bad
      #   a = 'a'
      #   foo if a == 'a' || a == 'b' || a == 'c'
      #
      #   # good
      #   a = 'a'
      #   foo if ['a', 'b', 'c'].include?(a)
      #
      #   VALUES = Set['a', 'b', 'c'].freeze
      #   # elsewhere...
      #   foo if VALUES.include?(a)
      #
      #   case foo
      #   when 'a', 'b', 'c' then foo
      #   # ...
      #   end
      #
      #   # accepted (but consider `case` as above)
      #   foo if a == b.lightweight || a == b.heavyweight
      #
      # @example AllowMethodComparison: true (default)
      #   # good
      #   foo if a == b.lightweight || a == b.heavyweight
      #
      # @example AllowMethodComparison: false
      #   # bad
      #   foo if a == b.lightweight || a == b.heavyweight
      #
      #   # good
      #   foo if [b.lightweight, b.heavyweight].include?(a)
      #
      # @example ComparisonsThreshold: 2 (default)
      #   # bad
      #   foo if a == 'a' || a == 'b'
      #
      # @example ComparisonsThreshold: 3
      #   # good
      #   foo if a == 'a' || a == 'b'
      #
      class MultipleComparison < Base
        extend AutoCorrector

        MSG = 'Avoid comparing a variable with multiple items ' \
              'in a conditional, use `Array#include?` instead.'

        def on_new_investigation
          @last_comparison = nil
        end

        def on_or(node)
          reset_comparison if switch_comparison?(node)

          root_of_or_node = root_of_or_node(node)

          return unless node == root_of_or_node
          return unless nested_variable_comparison?(root_of_or_node)
          return if @allowed_method_comparison
          return if @compared_elements.size < comparisons_threshold

          add_offense(node) do |corrector|
            elements = @compared_elements.join(', ')
            prefer_method = "[#{elements}].include?(#{variables_in_node(node).first})"

            corrector.replace(node, prefer_method)
          end

          @last_comparison = node
        end

        private

        # @!method simple_double_comparison?(node)
        def_node_matcher :simple_double_comparison?, '(send $lvar :== $lvar)'

        # @!method simple_comparison_lhs?(node)
        def_node_matcher :simple_comparison_lhs?, <<~PATTERN
          (send $lvar :== $_)
        PATTERN

        # @!method simple_comparison_rhs?(node)
        def_node_matcher :simple_comparison_rhs?, <<~PATTERN
          (send $_ :== $lvar)
        PATTERN

        def nested_variable_comparison?(node)
          return false unless nested_comparison?(node)

          variables_in_node(node).count == 1
        end

        def variables_in_node(node)
          if node.or_type?
            node.node_parts.flat_map { |node_part| variables_in_node(node_part) }.uniq
          else
            variables_in_simple_node(node)
          end
        end

        def variables_in_simple_node(node)
          simple_double_comparison?(node) do |var1, var2|
            return [variable_name(var1), variable_name(var2)]
          end
          if (var, obj = simple_comparison_lhs?(node)) || (obj, var = simple_comparison_rhs?(node))
            @allowed_method_comparison = true if allow_method_comparison? && obj.send_type?
            @compared_elements << obj.source
            return [variable_name(var)]
          end

          []
        end

        def variable_name(node)
          node.children[0]
        end

        def nested_comparison?(node)
          if node.or_type?
            node.node_parts.all? { |node_part| comparison? node_part }
          else
            false
          end
        end

        def comparison?(node)
          simple_comparison_lhs?(node) || simple_comparison_rhs?(node) || nested_comparison?(node)
        end

        def root_of_or_node(or_node)
          return or_node unless or_node.parent

          if or_node.parent.or_type?
            root_of_or_node(or_node.parent)
          else
            or_node
          end
        end

        def switch_comparison?(node)
          return true if @last_comparison.nil?

          @last_comparison.descendants.none?(node)
        end

        def reset_comparison
          @compared_elements = []
          @allowed_method_comparison = false
        end

        def allow_method_comparison?
          cop_config.fetch('AllowMethodComparison', true)
        end

        def comparisons_threshold
          cop_config.fetch('ComparisonsThreshold', 2)
        end
      end
    end
  end
end
