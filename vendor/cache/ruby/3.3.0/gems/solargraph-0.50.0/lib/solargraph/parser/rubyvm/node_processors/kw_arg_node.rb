# frozen_string_literal: true

module Solargraph
  module Parser
    module Rubyvm
      module NodeProcessors
        class KwArgNode < Parser::NodeProcessor::Base
          def process
            locals.push Solargraph::Pin::Parameter.new(
              location: region.closure.location,
              closure: region.closure,
              comments: comments_for(node),
              name: node.children[0].children[0].to_s,
              assignment: require_keyword?(node) ? nil : node.children[0].children[1],
              asgn_code: require_keyword?(node) ? nil : region.code_for(node.children[0].children[1]),
              presence: region.closure.location.range,
              decl: require_keyword?(node) ? :kwarg : :kwoptarg
            )
            idx = region.closure.parameters.find_index { |par| [:kwrestarg, :blockarg].include?(par.decl) }
            if idx
              region.closure.parameters.insert idx, locals.last
            else
              region.closure.parameters.push locals.last
            end
            node.children[1] && NodeProcessor.process(node.children[1], region, pins, locals)
          end

          private

          def require_keyword? node
            # Ruby 2.7 changed required keywords to use a magic symbol instead
            # of nil in the assignment node
            node.children[0].children[1].nil? || node.children[0].children[1] == :NODE_SPECIAL_REQUIRED_KEYWORD
          end
        end
      end
    end
  end
end
