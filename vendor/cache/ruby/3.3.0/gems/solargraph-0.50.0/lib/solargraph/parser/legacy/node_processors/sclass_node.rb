# frozen_string_literal: true

module Solargraph
  module Parser
    module Legacy
      module NodeProcessors
        class SclassNode < Parser::NodeProcessor::Base
          def process
            sclass = node.children[0]
            if sclass.is_a?(AST::Node) && sclass.type == :self
              closure = region.closure
            elsif sclass.is_a?(AST::Node) && sclass.type == :casgn
              names = [region.closure.namespace, region.closure.name]
              if sclass.children[0].nil? && names.last != sclass.children[1].to_s
                names << sclass.children[1].to_s
              else
                names.concat [NodeMethods.unpack_name(sclass.children[0]), sclass.children[1].to_s]
              end
              name = names.reject(&:empty?).join('::')
              closure = Solargraph::Pin::Namespace.new(name: name, location: region.closure.location)
            elsif sclass.is_a?(AST::Node) && sclass.type == :const
              names = [region.closure.namespace, region.closure.name]
              also = NodeMethods.unpack_name(sclass)
              if also != region.closure.name
                names << also
              end
              name = names.reject(&:empty?).join('::')
              closure = Solargraph::Pin::Namespace.new(name: name, location: region.closure.location)
            else
              return
            end
            pins.push Solargraph::Pin::Singleton.new(
              location: get_node_location(node),
              closure: closure
            )
            process_children region.update(visibility: :public, scope: :class, closure: pins.last)
          end
        end
      end
    end
  end
end
