# frozen_string_literal: true

module Solargraph
  module Parser
    module Rubyvm
      module NodeProcessors
        class NamespaceNode < Parser::NodeProcessor::Base
          include NodeMethods

          def process
            sc = nil
            if node.type == :CLASS && !node.children[1].nil?
              sc = unpack_name(node.children[1])
            end
            loc = get_node_location(node)
            nspin = Solargraph::Pin::Namespace.new(
              type: node.type.to_s.downcase.to_sym,
              location: loc,
              closure: region.closure,
              name: unpack_name(node.children[0]),
              comments: comments_for(node),
              visibility: :public,
              gates: region.closure.gates.freeze
            )
            pins.push nspin
            unless sc.nil?
              pins.push Pin::Reference::Superclass.new(
                location: loc,
                closure: pins.last,
                name: sc
              )
            end
            process_children region.update(closure: nspin, visibility: :public)
          end
        end
      end
    end
  end
end
