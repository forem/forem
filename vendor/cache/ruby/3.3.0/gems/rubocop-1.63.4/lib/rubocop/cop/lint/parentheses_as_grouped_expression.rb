# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for space between the name of a called method and a left
      # parenthesis.
      #
      # @example
      #
      #   # bad
      #   do_something (foo)
      #
      #   # good
      #   do_something(foo)
      #   do_something (2 + 3) * 4
      #   do_something (foo * bar).baz
      class ParenthesesAsGroupedExpression < Base
        include RangeHelp
        extend AutoCorrector

        MSG = '`%<argument>s` interpreted as grouped expression.'

        def on_send(node)
          return if valid_context?(node)

          space_length = spaces_before_left_parenthesis(node)
          return unless space_length.positive?

          range = space_range(node.first_argument.source_range, space_length)
          message = format(MSG, argument: node.first_argument.source)

          add_offense(range, message: message) { |corrector| corrector.remove(range) }
        end
        alias on_csend on_send

        private

        def valid_context?(node)
          unless node.arguments.one? && first_argument_starts_with_left_parenthesis?(node)
            return true
          end
          return true if first_argument_block_type?(node.first_argument)

          node.operator_method? || node.setter_method? || chained_calls?(node) ||
            valid_first_argument?(node.first_argument)
        end

        def first_argument_block_type?(first_arg)
          first_arg.block_type? || first_arg.numblock_type?
        end

        def valid_first_argument?(first_arg)
          first_arg.operator_keyword? || first_arg.hash_type? || ternary_expression?(first_arg)
        end

        def first_argument_starts_with_left_parenthesis?(node)
          node.first_argument.source.start_with?('(')
        end

        def chained_calls?(node)
          first_argument = node.first_argument
          first_argument.call_type? && (node.children.last&.children&.count || 0) > 1
        end

        def ternary_expression?(node)
          node.if_type? && node.ternary?
        end

        def spaces_before_left_parenthesis(node)
          receiver = node.receiver
          receiver_length = if receiver
                              receiver.source.length
                            else
                              0
                            end
          without_receiver = node.source[receiver_length..]

          # Escape question mark if any.
          method_regexp = Regexp.escape(node.method_name)

          match = without_receiver.match(/^\s*&?\.?\s*#{method_regexp}(\s+)\(/)
          match ? match.captures[0].length : 0
        end

        def space_range(expr, space_length)
          range_between(expr.begin_pos - space_length, expr.begin_pos)
        end
      end
    end
  end
end
