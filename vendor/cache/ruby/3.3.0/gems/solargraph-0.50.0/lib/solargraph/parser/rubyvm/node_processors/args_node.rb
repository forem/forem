# frozen_string_literal: true

module Solargraph
  module Parser
    module Rubyvm
      module NodeProcessors
        class ArgsNode < Parser::NodeProcessor::Base
          def process
            if region.closure.is_a?(Pin::Method) || region.closure.is_a?(Pin::Block)
              if region.lvars[0].nil?
                node.children[0].times do |i|
                  locals.push Solargraph::Pin::Parameter.new(
                    location: region.closure.location,
                    closure: region.closure,
                    comments: comments_for(node),
                    name: extract_name(node.children[i + 1]),
                    presence: region.closure.location.range,
                    decl: :arg
                  )
                  region.closure.parameters.push locals.last
                end
              else
                node.children[0].times do |i|
                  locals.push Solargraph::Pin::Parameter.new(
                    location: region.closure.location,
                    closure: region.closure,
                    comments: comments_for(node),
                    name: region.lvars[i].to_s,
                    presence: region.closure.location.range,
                    decl: :arg
                  )
                  region.closure.parameters.push locals.last
                end
              end
              if node.children[6]
                locals.push Solargraph::Pin::Parameter.new(
                  location: region.closure.location,
                  closure: region.closure,
                  comments: comments_for(node),
                  name: node.children[6].to_s,
                  presence: region.closure.location.range,
                  decl: :restarg
                )
                region.closure.parameters.push locals.last
              end
              if node.children[8] && node.children[8].children.first
                locals.push Solargraph::Pin::Parameter.new(
                  location: region.closure.location,
                  closure: region.closure,
                  comments: comments_for(node),
                  name: node.children[8].children.first.to_s,
                  presence: region.closure.location.range,
                  decl: :kwrestarg
                )
                region.closure.parameters.push locals.last
              end
            end
            process_children
            if node.children.last
              locals.push Solargraph::Pin::Parameter.new(
                location: region.closure.location,
                closure: region.closure,
                comments: comments_for(node),
                name: node.children.last.to_s,
                presence: region.closure.location.range,
                decl: :blockarg
              )
              region.closure.parameters.push locals.last
            end
          end

          private

          def extract_name var
            if Parser.is_ast_node?(var)
              var.children[0].to_s
            else
              var.to_s
            end
          end
        end
      end
    end
  end
end
