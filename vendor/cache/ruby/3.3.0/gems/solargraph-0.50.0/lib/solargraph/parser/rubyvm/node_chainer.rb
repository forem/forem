# frozen_string_literal: true

module Solargraph
  module Parser
    module Rubyvm
      # A factory for generating chains from nodes.
      #
      class NodeChainer
        include Rubyvm::NodeMethods

        Chain = Source::Chain

        # @param node [Parser::AST::Node]
        # @param filename [String]
        def initialize node, filename = nil, in_block = false
          @node = node
          @filename = filename
          @in_block = in_block ? 1 : 0
        end

        # @return [Source::Chain]
        def chain
          links = generate_links(@node)
          Chain.new(links, @node, (Parser.is_ast_node?(@node) && @node.type == :SPLAT))
        end

        class << self
          # @param node [Parser::AST::Node]
          # @param filename [String]
          # @return [Source::Chain]
          def chain node, filename = nil, in_block = false
            NodeChainer.new(node, filename, in_block).chain
          end

          # @param code [String]
          # @return [Source::Chain]
          def load_string(code)
            node = Parser.parse(code.sub(/\.$/, ''))
            chain = NodeChainer.new(node).chain
            chain.links.push(Chain::Link.new) if code.end_with?('.')
            chain
          end
        end

        private

        # @param n [Parser::AST::Node]
        # @return [Array<Chain::Link>]
        def generate_links n
          return [] unless Parser.is_ast_node?(n)
          return generate_links(n.children[2]) if n.type == :SCOPE
          return generate_links(n.children[0]) if n.type == :SPLAT
          result = []
          if n.type == :ITER
            @in_block += 1
            result.concat generate_links(n.children[0])
            @in_block -= 1
          elsif n.type == :CALL || n.type == :OPCALL
            n.children[0..-3].each do |c|
              result.concat generate_links(c)
            end
            result.push Chain::Call.new(n.children[-2].to_s, node_to_argchains(n.children.last), @in_block > 0 || block_passed?(n))
          elsif n.type == :QCALL
            n.children[0..-3].each do |c|
              result.concat generate_links(c)
            end
            result.push Chain::QCall.new(n.children[-2].to_s, node_to_argchains(n.children.last), @in_block > 0 || block_passed?(n))
          elsif n.type == :ATTRASGN
            result.concat generate_links(n.children[0])
            result.push Chain::Call.new(n.children[1].to_s, node_to_argchains(n.children[2]), @in_block > 0 || block_passed?(n))
          elsif n.type == :VCALL
            result.push Chain::Call.new(n.children[0].to_s, [], @in_block > 0 || block_passed?(n))
          elsif n.type == :FCALL
            result.push Chain::Call.new(n.children[0].to_s, node_to_argchains(n.children[1]), @in_block > 0 || block_passed?(n))
          elsif n.type == :SELF
            result.push Chain::Head.new('self')
          elsif n.type == :ZSUPER
            result.push Chain::ZSuper.new('super', @in_block > 0 || block_passed?(n))
          elsif n.type == :SUPER
            result.push Chain::Call.new('super', node_to_argchains(n.children.last), @in_block > 0 || block_passed?(n))
          elsif [:COLON2, :COLON3, :CONST].include?(n.type)
            const = unpack_name(n)
            result.push Chain::Constant.new(const)
          elsif [:LVAR, :LASGN, :DVAR].include?(n.type)
            result.push Chain::Call.new(n.children[0].to_s)
          elsif [:IVAR, :IASGN].include?(n.type)
            result.push Chain::InstanceVariable.new(n.children[0].to_s)
          elsif [:CVAR, :CVASGN].include?(n.type)
            result.push Chain::ClassVariable.new(n.children[0].to_s)
          elsif [:GVAR, :GASGN].include?(n.type)
            result.push Chain::GlobalVariable.new(n.children[0].to_s)
          elsif n.type == :OP_ASGN_OR
            result.concat generate_links n.children[2]
          elsif [:class, :module, :def, :defs].include?(n.type)
            # @todo Undefined or what?
            result.push Chain::UNDEFINED_CALL
          elsif n.type == :AND
            result.concat generate_links(n.children.last)
          elsif n.type == :OR
            result.push Chain::Or.new([NodeChainer.chain(n.children[0], @filename), NodeChainer.chain(n.children[1], @filename)])
          elsif n.type == :begin
            result.concat generate_links(n.children[0])
          elsif n.type == :BLOCK_PASS
            result.push Chain::BlockVariable.new("&#{n.children[1].children[0].to_s}")
          elsif n.type == :HASH
            result.push Chain::Hash.new('::Hash', hash_is_splatted?(n))
          else
            lit = infer_literal_node_type(n)
            if lit
              if lit == '::Hash'
                result.push Chain::Hash.new(lit, hash_is_splatted?(n))
              else
                result.push Chain::Literal.new(lit)
              end
            else
              result.push Chain::Link.new
            end
            # result.push (lit ? Chain::Literal.new(lit) : Chain::Link.new)
          end
          result
        end

        def hash_is_splatted? node
          return false unless Parser.is_ast_node?(node.children[0]) && node.children[0].type == :LIST
          list = node.children[0].children
          eol = list.rindex(&:nil?)
          eol && Parser.is_ast_node?(list[eol + 1])
        end

        def block_passed? node
          node.children.last.is_a?(RubyVM::AbstractSyntaxTree::Node) && node.children.last.type == :BLOCK_PASS
        end

        def node_to_argchains node
          return [] unless Parser.is_ast_node?(node)
          if [:ZARRAY, :ARRAY, :LIST].include?(node.type)
            node.children[0..-2].map { |c| NodeChainer.chain(c) }
          elsif node.type == :SPLAT
            [NodeChainer.chain(node)]
          elsif node.type == :ARGSPUSH
            result = node_to_argchains(node.children[0])
            result.push NodeChainer.chain(node.children[1]) if Parser.is_ast_node?(node.children[1])
          elsif node.type == :ARGSCAT
            result = node.children[0].children[0..-2].map { |c| NodeChainer.chain(c) }
            result.push NodeChainer.chain(node.children[1])
            # @todo Smelly instance variable access
            result.last.instance_variable_set(:@splat, true)
            result
          elsif node.type == :BLOCK_PASS
            result = node_to_argchains(node.children[0])
            result.push Chain.new([Chain::BlockVariable.new("&#{node.children[1].children[0].to_s}")])
            result
          else
            []
          end
        end
      end
    end
  end
end
