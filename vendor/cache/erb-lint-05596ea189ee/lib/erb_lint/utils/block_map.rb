# frozen_string_literal: true

require 'better_html/ast/node'
require 'better_html/test_helper/ruby_node'

module ERBLint
  module Utils
    class BlockMap
      attr_reader :connections

      class ParseError < StandardError; end

      def initialize(processed_source)
        @processed_source = processed_source
        @entries = []
        @connections = []
        @ruby_code = ""
        build_map
      end

      def find_connected_nodes(other)
        connection = @connections.find { |conn| conn.include?(other) }
        connection&.nodes
      end

      private

      def erb_nodes
        erb_ast.descendants(:erb).sort { |a, b| a.loc.begin_pos <=> b.loc.begin_pos }
      end

      class Entry
        attr_reader :node, :erb_range, :ruby_range

        def initialize(node, ruby_range)
          @node = node
          @erb_range = node.loc.range
          @ruby_range = ruby_range
        end

        def contains_ruby_range?(range)
          range.begin >= @ruby_range.begin && range.end <= @ruby_range.end
        end
      end

      class ConnectedErbNodes
        attr_reader :type, :nodes

        def initialize(type, nodes)
          @type = type
          @nodes = ordered(nodes)
        end

        def concat(other)
          @nodes = ordered(@nodes.concat(other.nodes))
        end

        def include?(other)
          @nodes.map(&:loc).include?(other.loc)
        end

        def inspect
          "\#<#{self.class.name} type=#{type.inspect} nodes=#{nodes.inspect}>"
        end

        def &(other)
          nodes.select { |node| other.include?(node) }
        end

        private

        def ordered(nodes)
          nodes
            .uniq(&:loc)
            .sort { |a, b| a.loc.begin_pos <=> b.loc.begin_pos }
        end
      end

      def build_map
        erb_nodes.each do |erb_node|
          indicator_node, _, code_node, _ = *erb_node
          length = code_node.loc.size
          start = current_pos
          if indicator_node.nil?
            append("#{code_node.loc.source}\n")
          elsif block?(code_node.loc.source)
            append("src= #{code_node.loc.source}\n")
            start += 5
          else
            append("src=(#{code_node.loc.source});\n")
            start += 5
          end
          ruby_range = Range.new(start, start + length)
          @entries << Entry.new(erb_node, ruby_range)
        end

        ruby_node = BetterHtml::TestHelper::RubyNode.parse(@ruby_code)
        raise ParseError unless ruby_node

        ruby_node.descendants(:block, :if, :for).each do |node|
          @connections << ConnectedErbNodes.new(
            node.type,
            extract_map_locations(node)
              .map { |loc| find_entry(loc) }
              .compact.map(&:node)
          )
        end

        ruby_node.descendants(:kwbegin).each do |node|
          @connections << ConnectedErbNodes.new(
            :begin,
            (extract_map_locations(node) + rescue_locations(node))
              .map { |loc| find_entry(loc) }
              .compact.map(&:node)
          )
        end

        ruby_node.descendants(:case).each do |node|
          @connections << ConnectedErbNodes.new(
            node.type,
            (extract_map_locations(node) + when_locations(node))
              .map { |loc| find_entry(loc) }
              .compact.map(&:node)
          )
        end

        group_overlapping_connections
      end

      def block?(source)
        # taken from: action_view/template/handlers/erb/erubi.rb
        /\s*((\s+|\))do|\{)(\s*\|[^|]*\|)?\s*\Z/.match?(source)
      end

      def when_locations(node)
        node.child_nodes
          .select { |child| child.type?(:when) }
          .map { |child| extract_map_locations(child) }
          .flatten
      end

      def rescue_locations(node)
        node.child_nodes
          .select { |child| child.type?(:rescue) }
          .map(&:child_nodes)
          .flatten
          .select { |child| child.type?(:resbody) }
          .map { |child| extract_map_locations(child) }
          .flatten
      end

      def extract_map_locations(node)
        (
          case node.loc
          when Parser::Source::Map::Collection
            [node.loc.begin, node.loc.end]
          when Parser::Source::Map::Condition
            [node.loc.keyword, node.loc.begin, node.loc.else, node.loc.end]
          when Parser::Source::Map::Constant
            [node.loc.double_colon, node.loc.name, node.loc.operator]
          when Parser::Source::Map::Definition
            [node.loc.keyword, node.loc.operator, node.loc.name, node.loc.end]
          when Parser::Source::Map::For
            [node.loc.keyword, node.loc.in, node.loc.begin, node.loc.end]
          when Parser::Source::Map::Heredoc
            [node.loc.heredoc_body, node.loc.heredoc_end]
          when Parser::Source::Map::Keyword
            [node.loc.keyword, node.loc.begin, node.loc.end]
          when Parser::Source::Map::ObjcKwarg
            [node.loc.keyword, node.loc.operator, node.loc.argument]
          when Parser::Source::Map::RescueBody
            [node.loc.keyword, node.loc.assoc, node.loc.begin]
          when Parser::Source::Map::Send
            [node.loc.dot, node.loc.selector, node.loc.operator, node.loc.begin, node.loc.end]
          when Parser::Source::Map::Ternary
            [node.loc.question, node.loc.colon]
          when Parser::Source::Map::Variable
            [node.loc.name, node.loc.operator]
          end + [node.loc.expression]
        ).compact
      end

      def current_pos
        @ruby_code.size
      end

      def append(code)
        @ruby_code += code
      end

      def parser
        @processed_source.parser
      end

      def find_entry(range)
        return unless range
        @entries.find do |entry|
          entry.contains_ruby_range?(Range.new(range.begin_pos, range.end_pos))
        end
      end

      def group_overlapping_connections
        loop do
          first, second = find_overlapping_pair
          break unless first && second

          @connections.delete(second)
          first.concat(second)
        end
      end

      def find_overlapping_pair
        @connections.each do |first|
          @connections.each do |second|
            next if first == second
            return [first, second] if (first & second).any?
          end
        end
        nil
      end

      def erb_ast
        parser.ast
      end
    end
  end
end
