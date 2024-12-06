# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for empty `ensure` blocks
      #
      # @example
      #
      #   # bad
      #
      #   def some_method
      #     do_something
      #   ensure
      #   end
      #
      # @example
      #
      #   # bad
      #
      #   begin
      #     do_something
      #   ensure
      #   end
      #
      # @example
      #
      #   # good
      #
      #   def some_method
      #     do_something
      #   ensure
      #     do_something_else
      #   end
      #
      # @example
      #
      #   # good
      #
      #   begin
      #     do_something
      #   ensure
      #     do_something_else
      #   end
      class EmptyEnsure < Base
        extend AutoCorrector

        MSG = 'Empty `ensure` block detected.'

        def on_ensure(node)
          return if node.body

          add_offense(node.loc.keyword) { |corrector| corrector.remove(node.loc.keyword) }
        end
      end
    end
  end
end
