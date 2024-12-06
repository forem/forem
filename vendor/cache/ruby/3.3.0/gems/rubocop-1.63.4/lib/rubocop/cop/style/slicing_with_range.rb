# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks that arrays are not sliced with the redundant `ary[0..-1]`, replacing it with `ary`,
      # and ensures arrays are sliced with endless ranges instead of `ary[start..-1]` on Ruby 2.6+,
      # and with beginless ranges instead of `ary[nil..end]` on Ruby 2.7+.
      #
      # @safety
      #   This cop is unsafe because `x..-1` and `x..` are only guaranteed to
      #   be equivalent for `Array#[]`, `String#[]`, and the cop cannot determine what class
      #   the receiver is.
      #
      #   For example:
      #   [source,ruby]
      #   ----
      #   sum = proc { |ary| ary.sum }
      #   sum[-3..-1] # => -6
      #   sum[-3..] # Hangs forever
      #   ----
      #
      # @example
      #   # bad
      #   items[0..-1]
      #   items[0..nil]
      #   items[0...nil]
      #
      #   # good
      #   items
      #
      #   # bad
      #   items[1..-1]   # Ruby 2.6+
      #   items[1..nil]  # Ruby 2.6+
      #
      #   # good
      #   items[1..]     # Ruby 2.6+
      #
      #   # bad
      #   items[nil..42] # Ruby 2.7+
      #
      #   # good
      #   items[..42]    # Ruby 2.7+
      #   items[0..42]   # Ruby 2.7+
      #
      class SlicingWithRange < Base
        extend AutoCorrector
        extend TargetRubyVersion

        minimum_target_ruby_version 2.6

        MSG = 'Prefer `%<prefer>s` over `%<current>s`.'
        MSG_USELESS_RANGE = 'Remove the useless `%<prefer>s`.'
        RESTRICT_ON_SEND = %i[[]].freeze

        # @!method range_from_zero_till_minus_one?(node)
        def_node_matcher :range_from_zero_till_minus_one?, <<~PATTERN
          {
            (irange (int 0) {(int -1) nil})
            (erange (int 0) nil)
          }
        PATTERN

        # @!method range_till_minus_one?(node)
        def_node_matcher :range_till_minus_one?, <<~PATTERN
          {
            (irange !nil? {(int -1) nil})
            (erange !nil? nil)
          }
        PATTERN

        # @!method range_from_zero?(node)
        def_node_matcher :range_from_zero?, <<~PATTERN
          (irange nil !nil?)
        PATTERN

        def on_send(node)
          return unless node.arguments.one?

          range_node = node.first_argument
          selector = node.loc.selector
          unless (message, removal_range = offense_message_with_removal_range(range_node, selector))
            return
          end

          add_offense(selector, message: message) do |corrector|
            corrector.remove(removal_range)
          end
        end

        private

        def offense_message_with_removal_range(range_node, selector)
          if range_from_zero_till_minus_one?(range_node)
            [format(MSG_USELESS_RANGE, prefer: selector.source), selector]
          elsif range_till_minus_one?(range_node)
            [
              format(MSG, prefer: endless(range_node), current: selector.source), range_node.end
            ]
          elsif range_from_zero?(range_node) && target_ruby_version >= 2.7
            [
              format(MSG, prefer: beginless(range_node), current: selector.source), range_node.begin
            ]
          end
        end

        def endless(range_node)
          "[#{range_node.begin.source}#{range_node.loc.operator.source}]"
        end

        def beginless(range_node)
          "[#{range_node.loc.operator.source}#{range_node.end.source}]"
        end
      end
    end
  end
end
