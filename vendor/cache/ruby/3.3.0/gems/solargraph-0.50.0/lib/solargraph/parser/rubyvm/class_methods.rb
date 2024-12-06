require 'solargraph/parser/rubyvm/node_processors'
require 'solargraph/parser/rubyvm/node_wrapper'

module Solargraph
  module Parser
    module Rubyvm
      module ClassMethods
        # @param code [String]
        # @param filename [String]
        # @return [Array(Parser::AST::Node, Array<Parser::Source::Comment>)]
        # @sg-ignore
        def parse_with_comments code, filename = nil
          node = RubyVM::AbstractSyntaxTree.parse(code).children[2]
          node &&= RubyVM::AbstractSyntaxTree::NodeWrapper.from(node, code.lines)
          comments = CommentRipper.new(code).parse
          [node, comments]
        rescue ::SyntaxError => e
          raise Parser::SyntaxError, e.message
        end

        # @param code [String]
        # @param filename [String, nil]
        # @param line [Integer]
        # @return [Parser::AST::Node]
        # @sg-ignore
        def parse code, filename = nil, line = 0
          node = RubyVM::AbstractSyntaxTree.parse(code).children[2]
          node and RubyVM::AbstractSyntaxTree::NodeWrapper.from(node, code.lines)
        rescue ::SyntaxError => e
          raise Parser::SyntaxError, e.message
        end

        def map source
          NodeProcessor.process(source.node, Region.new(source: source))
        end

        def references source, name
          if name.end_with?("=")
            reg = /#{Regexp.escape name[0..-2]}\s*=/
            extract_offset = ->(code, offset) { reg.match(code, offset).offset(0) }
          else
            extract_offset = ->(code, offset) { [soff = code.index(name, offset), soff + name.length] }
          end
          inner_node_references(name, source.node).map do |n|
            rng = Range.from_node(n)
            offset = Position.to_offset(source.code, rng.start)
            soff, eoff = extract_offset[source.code, offset]
            Location.new(
              source.filename,
              Range.new(
                Position.from_offset(source.code, soff),
                Position.from_offset(source.code, eoff)
              )
            )
          end
        end

        # @param name [String]
        # @param top [AST::Node]
        # @return [Array<AST::Node>]
        def inner_node_references name, top
          result = []
          if Parser.rubyvm?
            if Parser.is_ast_node?(top)
              result.push top if match_rubyvm_node_to_ref(top, name)
              top.children.each { |c| result.concat inner_node_references(name, c) }
            end
          else
            if Parser.is_ast_node?(top) && top.to_s.include?(":#{name}")
              result.push top if top.children.any? { |c| c.to_s == name }
              top.children.each { |c| result.concat inner_node_references(name, c) }
            end
          end
          result
        end

        def match_rubyvm_node_to_ref(top, name)
          top.children.select { |c| c.is_a?(Symbol) }.any? { |c| c.to_s == name } ||
            top.children.select { |c| c.is_a?(Array) }.any? { |c| c.include?(name.to_sym) }
        end

        def chain *args
          NodeChainer.chain *args
        end

        def chain_string *args
          NodeChainer.load_string *args
        end

        def process_node *args
          Solargraph::Parser::NodeProcessor.process *args
        end

        def infer_literal_node_type node
          NodeMethods.infer_literal_node_type node
        end

        def version
          Ruby::VERSION
        end

        def is_ast_node? node
          if Parser.rubyvm?
            node.is_a?(RubyVM::AbstractSyntaxTree::Node)
          else
            node.is_a?(::Parser::AST::Node)
          end
        end

        def node_range node
          st = Position.new(node.first_lineno - 1, node.first_column)
          en = Position.new(node.last_lineno - 1, node.last_column)
          Range.new(st, en)
        end

        def recipient_node tree
          tree.each_with_index do |node, idx|
            return tree[idx + 1] if [:ARRAY, :ZARRAY, :LIST].include?(node.type) && tree[idx + 1] && [:FCALL, :VCALL, :CALL].include?(tree[idx + 1].type)
          end
          nil
        end

        def string_ranges node
          return [] unless is_ast_node?(node)
          result = []
          if node.type == :STR
            result.push Range.from_node(node)
          elsif node.type == :DSTR
            here = Range.from_node(node)
            there = Range.from_node(node.children[1])
            result.push Range.new(here.start, there&.start || here.ending)
          end
          node.children.each do |child|
            result.concat string_ranges(child)
          end
          if node.type == :DSTR && node.children.last.nil?
            last = node.children[-2]
            unless last.nil?
              rng = Range.from_node(last)
              pos = Position.new(rng.ending.line, rng.ending.column - 1)
              result.push Range.new(pos, pos)
            end
          end
          result
        end
      end
    end
  end
end
