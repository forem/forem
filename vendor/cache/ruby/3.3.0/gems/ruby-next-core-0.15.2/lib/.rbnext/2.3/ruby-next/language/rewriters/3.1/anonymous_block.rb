# frozen_string_literal: true

module RubyNext
  module Language
    module Rewriters
      class AnonymousBlock < Base
        NAME = "anonymous-block"
        SYNTAX_PROBE = "obj = Object.new; def obj.foo(&) bar(&); end"
        MIN_SUPPORTED_VERSION = Gem::Version.new("3.1.0")

        BLOCK = :__block__

        def on_args(node)
          block = node.children.last

          return super unless ((((__safe_lvar__ = block) || true) && (!__safe_lvar__.nil? || nil)) && __safe_lvar__.type) == :blockarg
          return super unless block.children.first.nil?

          context.track! self

          replace(block.loc.expression, "&#{BLOCK}")

          node.updated(
            :args,
            [
              *node.children.slice(0, node.children.index(block)),
              s(:blockarg, BLOCK)
            ]
          )
        end

        def on_send(node)
          block = extract_block_pass(node)
          return super unless ((((__safe_lvar__ = block) || true) && (!__safe_lvar__.nil? || nil)) && __safe_lvar__.children) == [nil]

          process_block(node, block)
        end

        def on_super(node)
          block = extract_block_pass(node)
          return super unless ((((__safe_lvar__ = block) || true) && (!__safe_lvar__.nil? || nil)) && __safe_lvar__.children) == [nil]

          process_block(node, block)
        end

        private

        def extract_block_pass(node)
          node.children.find { |child| child.is_a?(::Parser::AST::Node) && child.type == :block_pass }
        end

        def process_block(node, block)
          replace(block.loc.expression, "&#{BLOCK}")

          process(
            node.updated(
              nil,
              [
                *node.children.take(node.children.index(block)),
                s(:block_pass, s(:lvar, BLOCK))
              ]
            )
          )
        end
      end
    end
  end
end
