# frozen_string_literal: true

require 'ast'

module I18n::Tasks::Scanners
  class RubyAstCallFinder
    include AST::Processor::Mixin

    # @param root_node [Parser::AST:Node]
    # @return [Pair<Parser::AST::Node, method_name as string>] for all nodes with :send type
    def collect_calls(root_node)
      @results = []
      process(root_node)
      @results
    end

    def on_def(node)
      @method_name = node.children[0]
      handler_missing(node)
    ensure
      @method_name = nil
    end

    def on_send(send_node)
      @results << [send_node, @method_name]

      # always invoke handler_missing to get nested translations in children
      handler_missing(send_node)
      nil
    end

    def handler_missing(node)
      node.children.each { |child| process(child) if child.is_a?(::Parser::AST::Node) }
      nil
    end
  end
end
