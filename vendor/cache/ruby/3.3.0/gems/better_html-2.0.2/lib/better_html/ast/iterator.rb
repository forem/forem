# frozen_string_literal: true

require "ast"
require "active_support/core_ext/array/wrap"

module BetterHtml
  module AST
    class Iterator
      class << self
        def descendants(root_node, type)
          Enumerator.new do |yielder|
            t = new(type) { |node| yielder << node }
            t.traverse(root_node)
          end
        end
      end

      def initialize(types, &block)
        @types = types.nil? ? nil : Array.wrap(types)
        @block = block
      end

      def traverse(node)
        return unless node.is_a?(::AST::Node)

        @block.call(node) if @types.nil? || @types.include?(node.type)
        traverse_all(node)
      end

      def traverse_all(nodes)
        nodes.to_a.each do |node|
          traverse(node) if node.is_a?(::AST::Node)
        end
      end
    end
  end
end
