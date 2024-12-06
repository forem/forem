# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for redundant dot before operator method call.
      # The target operator methods are `|`, `^`, `&`, ``<=>``, `==`, `===`, `=~`, `>`, `>=`, `<`,
      # ``<=``, `<<`, `>>`, `+`, `-`, `*`, `/`, `%`, `**`, `~`, `!`, `!=`, and `!~`.
      #
      # @example
      #
      #   # bad
      #   foo.+ bar
      #   foo.& bar
      #
      #   # good
      #   foo + bar
      #   foo & bar
      #
      class OperatorMethodCall < Base
        extend AutoCorrector

        MSG = 'Redundant dot detected.'
        RESTRICT_ON_SEND = %i[| ^ & <=> == === =~ > >= < <= << >> + - * / % ** ~ ! != !~].freeze

        # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
        def on_send(node)
          return unless (dot = node.loc.dot)
          return if node.receiver.const_type? || !node.arguments.one?

          _lhs, _op, rhs = *node
          return if !rhs || method_call_with_parenthesized_arg?(rhs) || anonymous_forwarding?(rhs)

          add_offense(dot) do |corrector|
            wrap_in_parentheses_if_chained(corrector, node)
            corrector.replace(dot, ' ')

            selector = node.loc.selector
            corrector.insert_after(selector, ' ') if selector.end_pos == rhs.source_range.begin_pos
          end
        end
        # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity

        private

        # Checks for an acceptable case of `foo.+(bar).baz`.
        def method_call_with_parenthesized_arg?(argument)
          return false unless argument.parent.parent&.send_type?

          argument.children.first && argument.parent.parenthesized?
        end

        def anonymous_forwarding?(argument)
          return true if argument.forwarded_args_type? || argument.forwarded_restarg_type?
          return true if argument.hash_type? && argument.children.first&.forwarded_kwrestarg_type?

          argument.block_pass_type? && argument.source == '&'
        end

        def wrap_in_parentheses_if_chained(corrector, node)
          return unless node.parent&.call_type?
          return if node.parent.first_argument == node

          operator = node.loc.selector

          ParenthesesCorrector.correct(corrector, node)
          corrector.insert_after(operator, ' ')
          corrector.wrap(node, '(', ')')
        end
      end
    end
  end
end
