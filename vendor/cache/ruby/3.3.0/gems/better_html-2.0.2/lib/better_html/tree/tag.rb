# frozen_string_literal: true

require "better_html/tree/attributes_list"
require "better_html/ast/iterator"

module BetterHtml
  module Tree
    class Tag
      attr_reader :node, :start_solidus, :name_node, :attributes_node, :end_solidus

      class << self
        def from_node(node)
          new(node)
        end
      end

      def initialize(node)
        @node = node
        @start_solidus, @name_node, @attributes_node, @end_solidus = *node
      end

      def loc
        @node.loc
      end

      def name
        @name_node&.loc&.source&.downcase
      end

      def closing?
        @start_solidus&.type == :solidus
      end

      def self_closing?
        @end_solidus&.type == :solidus
      end

      def attributes
        @attributes ||= AttributesList.from_nodes(@attributes_node.to_a)
      end
    end
  end
end
