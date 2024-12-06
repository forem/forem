# frozen_string_literal: true

require "better_html/errors"
require "better_html/tree/tag"
require "better_html/test_helper/safety_error"
require "ast"

module BetterHtml
  module TestHelper
    module SafeErb
      class Base
        attr_reader :errors

        def initialize(parser, config: BetterHtml.config)
          @parser = parser
          @config = config
          @errors = BetterHtml::Errors.new
        end

        def add_error(message, location:)
          @errors.add(SafetyError.new(message, location: location))
        end

        protected

        def erb_nodes(root_node)
          Enumerator.new do |yielder|
            next if root_node.nil?

            root_node.descendants(:erb).each do |erb_node|
              indicator_node, _, code_node, _ = *erb_node
              yielder.yield(erb_node, indicator_node, code_node)
            end
          end
        end

        def script_tags
          Enumerator.new do |yielder|
            @parser.nodes_with_type(:tag).each do |tag_node|
              tag = Tree::Tag.from_node(tag_node)
              next if tag.closing?

              next unless tag.name == "script"

              index = ast.to_a.find_index(tag_node)
              next_node = ast.to_a[index + 1]

              yielder.yield(tag, next_node&.type == :text ? next_node : nil)
            end
          end
        end

        def ast
          @parser.ast
        end
      end
    end
  end
end
