# frozen_string_literal: true

module RubyNext
  module Language
    module Rewriters
      class ArgsForward < Base
        NAME = "args-forward"
        SYNTAX_PROBE = "obj = Object.new; def obj.foo(...) super(...); end"
        MIN_SUPPORTED_VERSION = Gem::Version.new("2.7.0")

        REST = :__rest__
        BLOCK = :__block__

        def on_args(node)
          farg = node.children.find { |child| child.is_a?(::Parser::AST::Node) && child.type == :forward_arg }
          return unless farg

          context.track! self

          node = super(node)

          replace(farg.loc.expression, "*#{REST}, &#{BLOCK}")

          node.updated(
            :args,
            [
              *node.children.slice(0, node.children.index(farg)),
              s(:restarg, REST),
              s(:blockarg, BLOCK)
            ]
          )
        end

        def on_send(node)
          fargs = extract_fargs(node)
          return super(node) unless fargs

          process_fargs(node, fargs)
        end

        def on_super(node)
          fargs = extract_fargs(node)
          return super(node) unless fargs

          process_fargs(node, fargs)
        end

        def on_def(node)
          return super unless forward_arg?(node.children[1])

          new_node = super

          name = node.children[0]

          insert_after(node.loc.expression, "; respond_to?(:ruby2_keywords, true) && (ruby2_keywords :#{name})")

          s(:begin,
            new_node,
            ruby2_keywords_node(nil, name))
        end

        def on_defs(node)
          return super unless forward_arg?(node.children[2])

          new_node = super

          receiver = node.children[0]
          name = node.children[1]

          # Using self.ruby2_keywords :name results in undefined method error,
          # singleton_class works as expected
          receiver = s(:send, nil, :singleton_class) if receiver.type == :self

          receiver_name =
            case receiver.type
            when :send
              receiver.children[1]
            when :const
              receiver.children[1]
            end

          insert_after(node.loc.expression, "; #{receiver_name}.respond_to?(:ruby2_keywords, true) && (#{receiver_name}.send(:ruby2_keywords, :#{name}))")

          s(:begin,
            new_node,
            ruby2_keywords_node(receiver, name))
        end

        private

        def ruby2_keywords_node(receiver, name)
          s(:and,
            s(:send, receiver, :respond_to?,
              s(:sym, :ruby2_keywords), s(:true)),
            s(:begin,
              s(:send, receiver, :send,
                s(:sym, :ruby2_keywords),
                s(:sym, name))))
        end

        def forward_arg?(args)
          return false unless ((((__safe_lvar__ = args) || true) && (!__safe_lvar__.nil? || nil)) && __safe_lvar__.children)

          args.children.any? { |arg| arg.type == :forward_arg }
        end

        def extract_fargs(node)
          node.children.find { |child| child.is_a?(::Parser::AST::Node) && child.type == :forwarded_args }
        end

        def process_fargs(node, fargs)
          replace(fargs.loc.expression, "*#{REST}, &#{BLOCK}")

          process(
            node.updated(
              nil,
              [
                *node.children.take(node.children.index(fargs)),
                *forwarded_args
              ]
            )
          )
        end

        def forwarded_args
          [
            s(:splat, s(:lvar, REST)),
            s(:block_pass, s(:lvar, BLOCK))
          ]
        end
      end
    end
  end
end
