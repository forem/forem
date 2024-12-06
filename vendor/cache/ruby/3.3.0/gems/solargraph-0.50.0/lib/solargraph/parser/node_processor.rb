# frozen_string_literal: true

module Solargraph
  module Parser
    # The processor classes used by SourceMap::Mapper to generate pins from
    # parser nodes.
    #
    module NodeProcessor
      autoload :Base, 'solargraph/parser/node_processor/base'

      class << self
        @@processors ||= {}

        # Register a processor for a node type.
        #
        # @param type [Symbol]
        # @param cls [Class<NodeProcessor::Base>]
        # @return [Class<NodeProcessor::Base>]
        def register type, cls
          @@processors[type] = cls
        end
      end

      # @param node [Parser::AST::Node]
      # @param region [Region]
      # @param pins [Array<Pin::Base>]
      # @return [Array(Array<Pin::Base>, Array<Pin::Base>)]
      def self.process node, region = Region.new, pins = [], locals = []
        if pins.empty?
          pins.push Pin::Namespace.new(
            location: region.source.location,
            name: ''
          )
        end
        return [pins, locals] unless Parser.is_ast_node?(node)
        klass = @@processors[node.type] || NodeProcessor::Base
        processor = klass.new(node, region, pins, locals)
        processor.process
        [processor.pins, processor.locals]
      end
    end
  end
end
