require 'delegate'

module RubyVM::AbstractSyntaxTree
  # Wrapper for RubyVM::AbstractSyntaxTree::Node. for return character based column
  class NodeWrapper < SimpleDelegator
    attr_reader :code
    # @param node [RubyVM::AbstractSyntaxTree::Node] wrapped node to return character based column
    # @param code [Array<String>] source code lines for generated this node
    def initialize(node, code)
      @code = code
      super(node)
    end

    def self.from(node, code)
      return node unless node.is_a?(RubyVM::AbstractSyntaxTree::Node) and !node.kind_of?(SimpleDelegator)

      new(node, code)
    end

    def is_a?(type)
      __getobj__.is_a?(type) || super.is_a?(type)
    end

    def class
      __getobj__.class
    end


    def first_column
      @first_column ||= begin
        line = @code[__getobj__.first_lineno - 1] || ""
        line.byteslice(0, __getobj__.first_column).length
      end
    end

    def last_column
      @last_column ||= begin
        line = @code[__getobj__.last_lineno - 1] || ""
        line.byteslice(0, __getobj__.last_column).length
      end
    end

    def children
      @children ||= __getobj__.children.map do |node| NodeWrapper.from(node, @code) end
    end
  end
end
