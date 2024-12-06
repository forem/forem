# frozen_string_literal: true

module Solargraph
  module Parser
    module Legacy
      module NodeProcessors
        class IvasgnNode < Parser::NodeProcessor::Base
          include Legacy::NodeMethods

          def process
            loc = get_node_location(node)
            pins.push Solargraph::Pin::InstanceVariable.new(
              location: loc,
              closure: region.closure,
              name: node.children[0].to_s,
              comments: comments_for(node),
              assignment: node.children[1]
            )
            if region.visibility == :module_function
              here = get_node_start_position(node)
              named_path = named_path_pin(here)
              if named_path.is_a?(Pin::Method)
                pins.push Solargraph::Pin::InstanceVariable.new(
                  location: loc,
                  closure: Pin::Namespace.new(type: :module, closure: region.closure.closure, name: region.closure.name),
                  name: node.children[0].to_s,
                  comments: comments_for(node),
                  assignment: node.children[1]
                )
              end
            end
            process_children
          end
        end
      end
    end
  end
end
