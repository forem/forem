# frozen_string_literal: true

module RuboCop
  module Cop
    module Performance
      # Identifies places where numeric argument to BigDecimal should be
      # converted to string. Initializing from String is faster
      # than from Numeric for BigDecimal.
      #
      # @example
      #   # bad
      #   BigDecimal(1, 2)
      #   4.to_d(6)
      #   BigDecimal(1.2, 3, exception: true)
      #   4.5.to_d(6, exception: true)
      #
      #   # good
      #   BigDecimal('1', 2)
      #   BigDecimal('4', 6)
      #   BigDecimal('1.2', 3, exception: true)
      #   BigDecimal('4.5', 6, exception: true)
      #
      class BigDecimalWithNumericArgument < Base
        extend AutoCorrector

        MSG = 'Convert numeric literal to string and pass it to `BigDecimal`.'
        RESTRICT_ON_SEND = %i[BigDecimal to_d].freeze

        def_node_matcher :big_decimal_with_numeric_argument?, <<~PATTERN
          (send nil? :BigDecimal $numeric_type? ...)
        PATTERN

        def_node_matcher :to_d?, <<~PATTERN
          (send [!nil? $numeric_type?] :to_d ...)
        PATTERN

        def on_send(node)
          if (numeric = big_decimal_with_numeric_argument?(node))
            add_offense(numeric.source_range) do |corrector|
              corrector.wrap(numeric, "'", "'")
            end
          elsif (numeric_to_d = to_d?(node))
            add_offense(numeric_to_d.source_range) do |corrector|
              big_decimal_args = node.arguments.map(&:source).unshift("'#{numeric_to_d.source}'").join(', ')

              corrector.replace(node, "BigDecimal(#{big_decimal_args})")
            end
          end
        end
      end
    end
  end
end
