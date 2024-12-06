# frozen_string_literal: true

module Solargraph
  module Pin
    class BaseVariable < Base
      include Solargraph::Parser::NodeMethods
      # include Solargraph::Source::NodeMethods

      # @return [Parser::AST::Node, nil]
      attr_reader :assignment

      # @param assignment [Parser::AST::Node, nil]
      def initialize assignment: nil, **splat
        super(**splat)
        @assignment = assignment
      end

      def completion_item_kind
        Solargraph::LanguageServer::CompletionItemKinds::VARIABLE
      end

      # @return [Integer]
      def symbol_kind
        Solargraph::LanguageServer::SymbolKinds::VARIABLE
      end

      def return_type
        @return_type ||= generate_complex_type
      end

      def nil_assignment?
        return_type.nil?
      end

      def variable?
        true
      end

      def probe api_map
        return ComplexType::UNDEFINED if @assignment.nil?
        types = []
        returns_from(@assignment).each do |node|
          # Nil nodes may not have a location
          if node.nil? || node.type == :NIL || node.type == :nil
            types.push ComplexType::NIL
          else
            rng = Range.from_node(node)
            next if rng.nil?
            pos = rng.ending
            clip = api_map.clip_at(location.filename, pos)
            # Use the return node for inference. The clip might infer from the
            # first node in a method call instead of the entire call.
            chain = Parser.chain(node, nil, clip.in_block?)
            result = chain.infer(api_map, closure, clip.locals)
            types.push result unless result.undefined?
          end
        end
        return ComplexType::UNDEFINED if types.empty?
        ComplexType.try_parse(*types.map(&:to_s))
      end

      def == other
        return false unless super
        assignment == other.assignment
      end

      def try_merge! pin
        return false unless super
        @assignment = pin.assignment
        @return_type = pin.return_type
        true
      end

      private

      # @return [ComplexType]
      def generate_complex_type
        tag = docstring.tag(:type)
        return ComplexType.try_parse(*tag.types) unless tag.nil? || tag.types.nil? || tag.types.empty?
        ComplexType.new
      end
    end
  end
end
