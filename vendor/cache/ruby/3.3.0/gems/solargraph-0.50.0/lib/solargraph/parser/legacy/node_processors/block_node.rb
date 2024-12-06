# frozen_string_literal: true

module Solargraph
  module Parser
    module Legacy
      module NodeProcessors
        class BlockNode < Parser::NodeProcessor::Base
          include Legacy::NodeMethods

          def process
            location = get_node_location(node)
            parent = if other_class_eval?
              Solargraph::Pin::Namespace.new(
                location: location,
                type: :class,
                name: unpack_name(node.children[0].children[0])
              )
            else
              region.closure
            end
            pins.push Solargraph::Pin::Block.new(
              location: location,
              closure: parent,
              receiver: node.children[0],
              comments: comments_for(node),
              scope: region.scope || region.closure.context.scope
            )
            process_children region.update(closure: pins.last)
          end

          private

          def other_class_eval?
            node.children[0].type == :send &&
              node.children[0].children[1] == :class_eval &&
              [:cbase, :const].include?(node.children[0].children[0]&.type)
          end
        end
      end
    end
  end
end
