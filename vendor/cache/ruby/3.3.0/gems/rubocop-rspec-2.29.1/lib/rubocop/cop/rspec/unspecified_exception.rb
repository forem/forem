# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks for a specified error in checking raised errors.
      #
      # Enforces one of an Exception type, a string, or a regular
      # expression to match against the exception message as a parameter
      # to `raise_error`
      #
      # @example
      #   # bad
      #   expect {
      #     raise StandardError.new('error')
      #   }.to raise_error
      #
      #   # good
      #   expect {
      #     raise StandardError.new('error')
      #   }.to raise_error(StandardError)
      #
      #   expect {
      #     raise StandardError.new('error')
      #   }.to raise_error('error')
      #
      #   expect {
      #     raise StandardError.new('error')
      #   }.to raise_error(/err/)
      #
      #   expect { do_something }.not_to raise_error
      #
      class UnspecifiedException < Base
        MSG = 'Specify the exception being captured'
        RESTRICT_ON_SEND = %i[to].freeze

        # @!method empty_raise_error_or_exception(node)
        def_node_matcher :empty_raise_error_or_exception, <<~PATTERN
          (send
            (block
                (send nil? :expect) ...)
            :to
            (send nil? {:raise_error :raise_exception})
          )
        PATTERN

        def on_send(node)
          return unless empty_exception_matcher?(node)

          add_offense(node.children.last)
        end

        private

        def empty_exception_matcher?(node)
          empty_raise_error_or_exception(node) && !block_with_args?(node.parent)
        end

        def block_with_args?(node)
          return false unless node&.block_type?

          node.arguments?
        end
      end
    end
  end
end
