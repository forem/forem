# frozen_string_literal: true

module Solargraph
  module Parser
    module Rubyvm
      module NodeProcessors
        class CasgnNode < Parser::NodeProcessor::Base
          def process
            pins.push Solargraph::Pin::Constant.new(
              location: get_node_location(node),
              closure: region.closure,
              name: const_name,
              comments: comments_for(node),
              assignment: node.children[2] || node.children[1]
            )
            process_children
          end

          private

          # @return [String]
          def const_name
            if Parser.is_ast_node?(node.children[0])
              Parser::NodeMethods.unpack_name(node.children[0])
            else
              node.children[0].to_s
            end
          end
        end
      end
    end
  end
end
