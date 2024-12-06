# frozen_string_literal: true

module Solargraph
  module Parser
    module Rubyvm
      module NodeProcessors
        class LitNode < Parser::NodeProcessor::Base
          def process
            if node.children[0].is_a?(Symbol)
              pins.push Solargraph::Pin::Symbol.new(
                get_node_location(node),
                ":#{node.children[0]}"
              )
            end
          end
        end
      end
    end
  end
end
