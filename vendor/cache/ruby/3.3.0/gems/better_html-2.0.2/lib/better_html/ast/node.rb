# frozen_string_literal: true

require "ast"
require_relative "iterator"

module BetterHtml
  module AST
    class Node < ::AST::Node
      attr_reader :loc

      def descendants(*types)
        AST::Iterator.descendants(self, types)
      end

      def location
        loc
      end
    end
  end
end
