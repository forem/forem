# frozen_string_literal: true

module Solargraph
  module Parser
    module Rubyvm
      module NodeProcessors
        class AliasNode < Parser::NodeProcessor::Base
          def process
            loc = get_node_location(node)
            pins.push Solargraph::Pin::MethodAlias.new(
              location: loc,
              closure: region.closure,
              name: node.children[0].children[0].to_s,
              original: node.children[1].children[0].to_s,
              scope: region.scope || :instance
            )
            process_children
          end
        end
      end
    end
  end
end
