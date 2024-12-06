# frozen_string_literal: true

module Solargraph
  module Parser
    module Rubyvm
      module NodeProcessors
        class OptArgNode < Parser::NodeProcessor::Base
          def process
            locals.push Solargraph::Pin::Parameter.new(
              location: region.closure.location,
              closure: region.closure,
              comments: comments_for(node),
              name: node.children[0].children[0].to_s,
              assignment: node.children[0].children[1],
              asgn_code: node.children[0].children[1] ? region.code_for(node.children[0].children[1]) : nil,
              presence: region.closure.location.range,
              decl: :optarg
            )
            region.closure.parameters.push locals.last
            node.children[1] && NodeProcessor.process(node.children[1], region, pins, locals)
          end
        end
      end
    end
  end
end
