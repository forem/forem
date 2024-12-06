# frozen_string_literal: true

module RuboCop
  module AST
    # A node extension for `casgn` nodes.
    # This will be used in place of a plain node when the builder constructs
    # the AST, making its methods available to all assignment nodes within RuboCop.
    class CasgnNode < Node
      # The namespace of the constant being assigned.
      #
      # @return [Node, nil] the node associated with the scope (e.g. cbase, const, ...)
      def namespace
        node_parts[0]
      end

      # The name of the variable being assigned as a symbol.
      #
      # @return [Symbol] the name of the variable being assigned
      def name
        node_parts[1]
      end

      # The expression being assigned to the variable.
      #
      # @return [Node] the expression being assigned.
      def expression
        node_parts[2]
      end
    end
  end
end
