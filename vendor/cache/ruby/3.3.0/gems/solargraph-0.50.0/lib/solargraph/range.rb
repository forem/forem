# frozen_string_literal: true

module Solargraph
  # A pair of positions that compose a section of text.
  #
  class Range
    # @return [Position]
    attr_reader :start

    # @return [Position]
    attr_reader :ending

    # @param start [Position]
    # @param ending [Position]
    def initialize start, ending
      @start = start
      @ending = ending
    end

    # Get a hash of the range. This representation is suitable for use in
    # the language server protocol.
    #
    # @return [Hash<Symbol, Position>]
    def to_hash
      {
        start: start.to_hash,
        end: ending.to_hash
      }
    end

    # True if the specified position is inside the range.
    #
    # @param position [Position, Array(Integer, Integer)]
    # @return [Boolean]
    def contain? position
      position = Position.normalize(position)
      return false if position.line < start.line || position.line > ending.line
      return false if position.line == start.line && position.character < start.character
      return false if position.line == ending.line && position.character > ending.character
      true
    end

    # True if the range contains the specified position and the position does not precede it.
    #
    # @param position [Position, Array(Integer, Integer)]
    # @return [Boolean]
    def include? position
      position = Position.normalize(position)
      contain?(position) && !(position.line == start.line && position.character == start.character)
    end

    # Create a range from a pair of lines and characters.
    #
    # @param l1 [Integer] Starting line
    # @param c1 [Integer] Starting character
    # @param l2 [Integer] Ending line
    # @param c2 [Integer] Ending character
    # @return [Range]
    def self.from_to l1, c1, l2, c2
      Range.new(Position.new(l1, c1), Position.new(l2, c2))
    end

    # Get a range from a node.
    #
    # @param node [RubyVM::AbstractSyntaxTree::Node, Parser::AST::Node]
    # @return [Range]
    def self.from_node node
      if defined?(RubyVM::AbstractSyntaxTree::Node)
        if node.is_a?(RubyVM::AbstractSyntaxTree::Node)
          Solargraph::Range.from_to(node.first_lineno - 1, node.first_column, node.last_lineno - 1, node.last_column)
        end
      elsif node&.loc && node.loc.expression
        from_expr(node.loc.expression)
      end
    end

    # Get a range from a Parser range, usually found in
    # Parser::AST::Node#location#expression.
    #
    # @param expr [Parser::Source::Range]
    # @return [Range]
    def self.from_expr expr
      from_to(expr.line, expr.column, expr.last_line, expr.last_column)
    end

    def == other
      return false unless other.is_a?(Range)
      start == other.start && ending == other.ending
    end

    def inspect
      "#<#{self.class} #{start.inspect} to #{ending.inspect}>"
    end
  end
end
