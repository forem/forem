# frozen_string_literal: true

module Solargraph
  module Parser
    module Rubyvm
      module NodeProcessors
        class OrasgnNode < Parser::NodeProcessor::Base
          def process
            NodeProcessor.process(node.children[2], region, pins, locals)
          end
        end
      end
    end
  end
end
