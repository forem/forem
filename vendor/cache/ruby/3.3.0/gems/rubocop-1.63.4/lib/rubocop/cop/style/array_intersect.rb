# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # In Ruby 3.1, `Array#intersect?` has been added.
      #
      # This cop identifies places where `(array1 & array2).any?`
      # can be replaced by `array1.intersect?(array2)`.
      #
      # The `array1.intersect?(array2)` method is faster than
      # `(array1 & array2).any?` and is more readable.
      #
      # In cases like the following, compatibility is not ensured,
      # so it will not be detected when using block argument.
      #
      # [source,ruby]
      # ----
      # ([1] & [1,2]).any? { |x| false }    # => false
      # [1].intersect?([1,2]) { |x| false } # => true
      # ----
      #
      # @safety
      #   This cop cannot guarantee that `array1` and `array2` are
      #   actually arrays while method `intersect?` is for arrays only.
      #
      # @example
      #   # bad
      #   (array1 & array2).any?
      #   (array1 & array2).empty?
      #
      #   # good
      #   array1.intersect?(array2)
      #   !array1.intersect?(array2)
      #
      # @example AllCops:ActiveSupportExtensionsEnabled: false (default)
      #   # good
      #   (array1 & array2).present?
      #   (array1 & array2).blank?
      #
      # @example AllCops:ActiveSupportExtensionsEnabled: true
      #   # bad
      #   (array1 & array2).present?
      #   (array1 & array2).blank?
      #
      #   # good
      #   array1.intersect?(array2)
      #   !array1.intersect?(array2)
      class ArrayIntersect < Base
        extend AutoCorrector
        extend TargetRubyVersion

        minimum_target_ruby_version 3.1

        # @!method regular_bad_intersection_check?(node)
        def_node_matcher :regular_bad_intersection_check?, <<~PATTERN
          (send
            (begin
              (send $(...) :& $(...))
            ) ${:any? :empty?}
          )
        PATTERN

        # @!method active_support_bad_intersection_check?(node)
        def_node_matcher :active_support_bad_intersection_check?, <<~PATTERN
          (send
            (begin
              (send $(...) :& $(...))
            ) ${:present? :any? :blank? :empty?}
          )
        PATTERN

        MSG = 'Use `%<negated>s%<receiver>s.intersect?(%<argument>s)` ' \
              'instead of `(%<receiver>s & %<argument>s).%<method_name>s`.'
        STRAIGHT_METHODS = %i[present? any?].freeze
        NEGATED_METHODS = %i[blank? empty?].freeze
        RESTRICT_ON_SEND = (STRAIGHT_METHODS + NEGATED_METHODS).freeze

        def on_send(node)
          return if (parent = node.parent) && (parent.block_type? || parent.numblock_type?)
          return unless (receiver, argument, method_name = bad_intersection_check?(node))

          message = message(receiver.source, argument.source, method_name)

          add_offense(node, message: message) do |corrector|
            bang = straight?(method_name) ? '' : '!'

            corrector.replace(node, "#{bang}#{receiver.source}.intersect?(#{argument.source})")
          end
        end

        private

        def bad_intersection_check?(node)
          if active_support_extensions_enabled?
            active_support_bad_intersection_check?(node)
          else
            regular_bad_intersection_check?(node)
          end
        end

        def straight?(method_name)
          STRAIGHT_METHODS.include?(method_name.to_sym)
        end

        def message(receiver, argument, method_name)
          negated = straight?(method_name) ? '' : '!'
          format(
            MSG,
            negated: negated,
            receiver: receiver,
            argument: argument,
            method_name: method_name
          )
        end
      end
    end
  end
end
