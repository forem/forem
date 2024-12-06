# frozen_string_literal: true

module Solargraph
  module Parser
    module Legacy
      module NodeProcessors
        class ArgsNode < Parser::NodeProcessor::Base
          def process
            node.children.each do |u|
              loc = get_node_location(u)
              locals.push Solargraph::Pin::Parameter.new(
                location: loc,
                closure: region.closure,
                comments: comments_for(node),
                name: u.children[0].to_s,
                assignment: u.children[1],
                asgn_code: u.children[1] ? region.code_for(u.children[1]) : nil,
                presence: region.closure.location.range,
                decl: get_decl(u)
              )
              region.closure.parameters.push locals.last
            end
            process_children
          end

          private

          def get_decl node
            node.type
          end
        end
      end
    end
  end
end
