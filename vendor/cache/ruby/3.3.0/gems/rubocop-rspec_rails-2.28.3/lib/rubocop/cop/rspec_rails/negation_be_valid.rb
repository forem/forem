# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpecRails
      # Enforces use of `be_invalid` or `not_to` for negated be_valid.
      #
      # @safety
      #   This cop is unsafe because it cannot guarantee that
      #   the test target is an instance of `ActiveModel::Validations``.
      #
      # @example EnforcedStyle: not_to (default)
      #   # bad
      #   expect(foo).to be_invalid
      #
      #   # good
      #   expect(foo).not_to be_valid
      #
      #   # good (with method chain)
      #   expect(foo).to be_invalid.and be_odd
      #
      # @example EnforcedStyle: be_invalid
      #   # bad
      #   expect(foo).not_to be_valid
      #
      #   # good
      #   expect(foo).to be_invalid
      #
      #   # good (with method chain)
      #   expect(foo).to be_invalid.or be_even
      #
      class NegationBeValid < ::RuboCop::Cop::Base
        extend AutoCorrector
        include ConfigurableEnforcedStyle

        MSG = 'Use `expect(...).%<runner>s %<matcher>s`.'
        RESTRICT_ON_SEND = %i[be_valid be_invalid].freeze

        # @!method not_to?(node)
        def_node_matcher :not_to?, <<~PATTERN
          (send ... :not_to (send nil? :be_valid ...))
        PATTERN

        # @!method be_invalid?(node)
        def_node_matcher :be_invalid?, <<~PATTERN
          (send ... :to (send nil? :be_invalid ...))
        PATTERN

        def on_send(node)
          return unless offense?(node.parent)

          add_offense(offense_range(node),
                      message: message(node.method_name)) do |corrector|
            corrector.replace(node.parent.loc.selector, replaced_runner)
            corrector.replace(node.loc.selector, replaced_matcher)
          end
        end

        private

        def offense?(node)
          case style
          when :not_to
            be_invalid?(node)
          when :be_invalid
            not_to?(node)
          end
        end

        def offense_range(node)
          node.parent.loc.selector.with(end_pos: node.loc.selector.end_pos)
        end

        def message(_matcher)
          format(MSG, runner: replaced_runner, matcher: replaced_matcher)
        end

        def replaced_runner
          case style
          when :not_to
            'not_to'
          when :be_invalid
            'to'
          end
        end

        def replaced_matcher
          case style
          when :not_to
            'be_valid'
          when :be_invalid
            'be_invalid'
          end
        end
      end
    end
  end
end
