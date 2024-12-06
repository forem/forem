# frozen_string_literal: true

module Solargraph
  module Parser
    module Rubyvm
      module NodeProcessors
        class CvasgnNode < Parser::NodeProcessor::Base
          def process
            loc = get_node_location(node)
            pins.push Solargraph::Pin::ClassVariable.new(
              location: loc,
              closure: region.closure,
              name: node.children[0].to_s,
              comments: comments_for(node),
              assignment: node.children[1]
            )
            process_children
          end
        end
      end
    end
  end
end
