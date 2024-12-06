# frozen_string_literal: true

require "better_html/tree/attribute"

module BetterHtml
  module Tree
    class AttributesList
      class << self
        def from_nodes(nodes)
          new(nodes&.map { |node| Tree::Attribute.from_node(node) })
        end
      end

      def initialize(list)
        @list = list || []
      end

      def [](name)
        @list.find do |attribute|
          attribute.name == name.downcase
        end
      end

      def each(&block)
        @list.each(&block)
      end
    end
  end
end
