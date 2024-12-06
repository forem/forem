# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for the presence of `method_missing` without also
      # defining `respond_to_missing?`.
      #
      # @example
      #   # bad
      #   def method_missing(name, *args)
      #     # ...
      #   end
      #
      #   # good
      #   def respond_to_missing?(name, include_private)
      #     # ...
      #   end
      #
      #   def method_missing(name, *args)
      #     # ...
      #   end
      #
      class MissingRespondToMissing < Base
        MSG = 'When using `method_missing`, define `respond_to_missing?`.'

        def on_def(node)
          return unless node.method?(:method_missing)
          return if implements_respond_to_missing?(node)

          add_offense(node)
        end
        alias on_defs on_def

        private

        def implements_respond_to_missing?(node)
          return false unless (grand_parent = node.parent.parent)

          grand_parent.each_descendant(node.type) do |descendant|
            return true if descendant.method?(:respond_to_missing?)

            child = descendant.children.first
            return true if child.respond_to?(:method?) && child.method?(:respond_to_missing?)
          end

          false
        end
      end
    end
  end
end
