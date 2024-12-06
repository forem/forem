# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for numeric comparisons that can be replaced
      # by a predicate method, such as `receiver.length == 0`,
      # `receiver.length > 0`, and `receiver.length != 0`,
      # `receiver.length < 1` and `receiver.size == 0` that can be
      # replaced by `receiver.empty?` and `!receiver.empty?`.
      #
      # NOTE: `File`, `Tempfile`, and `StringIO` do not have `empty?`
      # so allow `size == 0` and `size.zero?`.
      #
      # @safety
      #   This cop is unsafe because it cannot be guaranteed that the receiver
      #   has an `empty?` method that is defined in terms of `length`. If there
      #   is a non-standard class that redefines `length` or `empty?`, the cop
      #   may register a false positive.
      #
      # @example
      #   # bad
      #   [1, 2, 3].length == 0
      #   0 == "foobar".length
      #   array.length < 1
      #   {a: 1, b: 2}.length != 0
      #   string.length > 0
      #   hash.size > 0
      #
      #   # good
      #   [1, 2, 3].empty?
      #   "foobar".empty?
      #   array.empty?
      #   !{a: 1, b: 2}.empty?
      #   !string.empty?
      #   !hash.empty?
      class ZeroLengthPredicate < Base
        extend AutoCorrector

        ZERO_MSG = 'Use `empty?` instead of `%<current>s`.'
        NONZERO_MSG = 'Use `!empty?` instead of `%<current>s`.'

        RESTRICT_ON_SEND = %i[size length].freeze

        def on_send(node)
          check_zero_length_predicate(node)
          check_zero_length_comparison(node)
          check_nonzero_length_comparison(node)
        end

        private

        def check_zero_length_predicate(node)
          return unless (length_method = zero_length_predicate(node.parent))
          return if non_polymorphic_collection?(node.parent)

          offense = node.loc.selector.join(node.parent.source_range.end)
          message = format(ZERO_MSG, current: "#{length_method}.zero?")

          add_offense(offense, message: message) do |corrector|
            corrector.replace(offense, 'empty?')
          end
        end

        def check_zero_length_comparison(node)
          zero_length_comparison = zero_length_comparison(node.parent)
          return unless zero_length_comparison

          lhs, opr, rhs = zero_length_comparison

          return if non_polymorphic_collection?(node.parent)

          add_offense(
            node.parent, message: format(ZERO_MSG, current: "#{lhs} #{opr} #{rhs}")
          ) do |corrector|
            corrector.replace(node.parent, replacement(node.parent))
          end
        end

        def check_nonzero_length_comparison(node)
          nonzero_length_comparison = nonzero_length_comparison(node.parent)
          return unless nonzero_length_comparison

          lhs, opr, rhs = nonzero_length_comparison

          return if non_polymorphic_collection?(node.parent)

          add_offense(
            node.parent, message: format(NONZERO_MSG, current: "#{lhs} #{opr} #{rhs}")
          ) do |corrector|
            corrector.replace(node.parent, replacement(node.parent))
          end
        end

        # @!method zero_length_predicate(node)
        def_node_matcher :zero_length_predicate, <<~PATTERN
          (send (send (...) ${:length :size}) :zero?)
        PATTERN

        # @!method zero_length_comparison(node)
        def_node_matcher :zero_length_comparison, <<~PATTERN
          {(send (send (...) ${:length :size}) $:== (int $0))
           (send (int $0) $:== (send (...) ${:length :size}))
           (send (send (...) ${:length :size}) $:<  (int $1))
           (send (int $1) $:> (send (...) ${:length :size}))}
        PATTERN

        # @!method nonzero_length_comparison(node)
        def_node_matcher :nonzero_length_comparison, <<~PATTERN
          {(send (send (...) ${:length :size}) ${:> :!=} (int $0))
           (send (int $0) ${:< :!=} (send (...) ${:length :size}))}
        PATTERN

        def replacement(node)
          receiver = zero_length_receiver(node)
          return "#{receiver.source}.empty?" if receiver

          "!#{other_receiver(node).source}.empty?"
        end

        # @!method zero_length_receiver(node)
        def_node_matcher :zero_length_receiver, <<~PATTERN
          {(send (send $_ _) :== (int 0))
           (send (int 0) :== (send $_ _))
           (send (send $_ _) :<  (int 1))
           (send (int 1) :> (send $_ _))}
        PATTERN

        # @!method other_receiver(node)
        def_node_matcher :other_receiver, <<~PATTERN
          {(send (send $_ _) _ _)
           (send _ _ (send $_ _))}
        PATTERN

        # Some collection like objects in the Ruby standard library
        # implement `#size`, but not `#empty`. We ignore those to
        # reduce false positives.
        # @!method non_polymorphic_collection?(node)
        def_node_matcher :non_polymorphic_collection?, <<~PATTERN
          {(send (send (send (const {nil? cbase} :File) :stat _) ...) ...)
           (send (send (send (const {nil? cbase} {:File :Tempfile :StringIO}) {:new :open} ...) ...) ...)}
        PATTERN
      end
    end
  end
end
