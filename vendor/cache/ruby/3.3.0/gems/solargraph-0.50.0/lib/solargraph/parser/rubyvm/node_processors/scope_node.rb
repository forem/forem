# frozen_string_literal: true

module Solargraph
  module Parser
    module Rubyvm
      module NodeProcessors
        class ScopeNode < Parser::NodeProcessor::Base
          def process
            process_children region.update(lvars: node.children[0])
          end
        end
      end
    end
  end
end
