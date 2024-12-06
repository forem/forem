# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for the use of a return with a value in a context
      # where the value will be ignored. (initialize and setter methods)
      #
      # @example
      #
      #   # bad
      #   def initialize
      #     foo
      #     return :qux if bar?
      #     baz
      #   end
      #
      #   def foo=(bar)
      #     return 42
      #   end
      #
      # @example
      #
      #   # good
      #   def initialize
      #     foo
      #     return if bar?
      #     baz
      #   end
      #
      #   def foo=(bar)
      #     return
      #   end
      class ReturnInVoidContext < Base
        MSG = 'Do not return a value in `%<method>s`.'

        def on_return(return_node)
          return unless return_node.descendants.any?

          context_node = non_void_context(return_node)

          return unless context_node&.def_type?
          return unless context_node&.void_context?

          add_offense(
            return_node.loc.keyword,
            message: format(message, method: context_node.method_name)
          )
        end

        private

        def non_void_context(return_node)
          return_node.each_ancestor(:block, :def, :defs).first
        end
      end
    end
  end
end
