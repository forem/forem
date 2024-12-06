# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Helper methods for top level example group cops
      module TopLevelGroup
        extend RuboCop::NodePattern::Macros

        def on_new_investigation
          super

          top_level_groups.each do |node|
            on_top_level_example_group(node) if example_group?(node)
            on_top_level_group(node)
          end
        end

        def top_level_groups
          @top_level_groups ||=
            top_level_nodes(root_node).select { |n| spec_group?(n) }
        end

        private

        # Dummy methods to be overridden in the consumer
        def on_top_level_example_group(_node); end

        def on_top_level_group(_node); end

        def top_level_group?(node)
          top_level_groups.include?(node)
        end

        def top_level_nodes(node)
          return [] if node.nil?

          case node.type
          when :begin
            node.children
          when :module, :class
            top_level_nodes(node.body)
          else
            [node]
          end
        end

        def root_node
          processed_source.ast
        end
      end
    end
  end
end
