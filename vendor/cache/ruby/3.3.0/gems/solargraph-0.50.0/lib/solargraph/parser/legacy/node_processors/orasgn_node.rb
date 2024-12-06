# frozen_string_literal: true

module Solargraph
  module Parser
    module Legacy
      module NodeProcessors
        class OrasgnNode < Parser::NodeProcessor::Base
          def process
            new_node = node.updated(node.children[0].type, node.children[0].children + [node.children[1]])
            NodeProcessor.process(new_node, region, pins, locals)
          end
        end
      end
    end
  end
end
