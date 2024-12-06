# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Identifies usages of `arr[0]` and `arr[-1]` and suggests to change
      # them to use `arr.first` and `arr.last` instead.
      #
      # The cop is disabled by default due to safety concerns.
      #
      # @safety
      #   This cop is unsafe because `[0]` or `[-1]` can be called on a Hash,
      #   which returns a value for `0` or `-1` key, but changing these to use
      #   `.first` or `.last` will return first/last tuple instead. Also, String
      #   does not implement `first`/`last` methods.
      #
      # @example
      #   # bad
      #   arr[0]
      #   arr[-1]
      #
      #   # good
      #   arr.first
      #   arr.last
      #   arr[0] = 2
      #   arr[0][-2]
      #
      class ArrayFirstLast < Base
        extend AutoCorrector

        MSG = 'Use `%<preferred>s`.'
        RESTRICT_ON_SEND = %i[[]].freeze

        # rubocop:disable Metrics/AbcSize
        def on_send(node)
          return unless node.arguments.size == 1 && node.first_argument.int_type?

          value = node.first_argument.value
          return unless [0, -1].include?(value)

          node = innermost_braces_node(node)
          return if node.parent && brace_method?(node.parent)

          preferred = (value.zero? ? 'first' : 'last')
          add_offense(node.loc.selector, message: format(MSG, preferred: preferred)) do |corrector|
            corrector.replace(node.loc.selector, ".#{preferred}")
          end
        end
        # rubocop:enable Metrics/AbcSize

        private

        def innermost_braces_node(node)
          node = node.receiver while node.receiver.send_type? && node.receiver.method?(:[])
          node
        end

        def brace_method?(node)
          node.send_type? && (node.method?(:[]) || node.method?(:[]=))
        end
      end
    end
  end
end
