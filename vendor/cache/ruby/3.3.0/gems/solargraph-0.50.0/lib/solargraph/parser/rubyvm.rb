module Solargraph
  module Parser
    module Rubyvm
      autoload :ClassMethods, 'solargraph/parser/rubyvm/class_methods'
      autoload :NodeChainer,  'solargraph/parser/rubyvm/node_chainer'
      autoload :NodeMethods,  'solargraph/parser/rubyvm/node_methods'
    end
  end
end

require 'solargraph/parser/rubyvm/node_processors'

class RubyVM::AbstractSyntaxTree::Node
  def to_sexp
    sexp self
  end

  def == other
    return false unless other.is_a?(self.class)
    here = Solargraph::Range.from_node(self)
    there = Solargraph::Range.from_node(other)
    here == there && to_sexp == other.to_sexp
  end

  private

  def sexp node, depth = 0
    result = ''
    if node.is_a?(RubyVM::AbstractSyntaxTree::Node)
      result += "#{'  ' * depth}(:#{node.type}"
      node.children.each do |child|
        result += "\n" + sexp(child, depth + 1)
      end
      result += ")"
    else
      result += "#{'  ' * depth}#{node.inspect}"
    end
    result
  end
end
