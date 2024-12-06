# frozen_string_literal: true

module RubyNext
  module Language
    module Rewriters
      class SafeNavigation < Base
        NAME = "safe-navigation"
        SYNTAX_PROBE = "nil&.x&.nil?"
        MIN_SUPPORTED_VERSION = Gem::Version.new("2.3.0")

        SAFE_LVAR = :__safe_lvar__

        def on_csend(node)
          node = super(node)

          context.track! self

          receiver, *args = *node

          new_node = s(:begin,
            node.updated(
              :and,
              [
                process(safe_navigation(receiver)),
                s(:send, safe_lvar, *args)
              ]
            ))

          replace(node.loc.expression, new_node)

          new_node
        end

        def on_block(node)
          return super(node) unless node.children[0].type == :csend

          context.track!(self)

          super(decsendize(node))
        end

        def on_numblock(node)
          return super(node) unless node.children[0].type == :csend

          context.track!(self)

          super(decsendize(node))
        end

        def on_op_asgn(node)
          return super(node) unless node.children[0].type == :csend

          context.track!(self)

          super(decsendize(node))
        end

        private

        def decsendize(node)
          csend, *children = node.children

          receiver, *other = csend.children

          new_csend = csend.updated(:send, [safe_lvar, *other])

          new_node = s(:begin,
            node.updated(
              :and,
              [
                process(safe_navigation(receiver)),
                process(node.updated(nil, [new_csend, *children]))
              ]
            ))

          replace(node.loc.expression, new_node)

          new_node
        end

        # Transform: x&.y -> ((_tmp_ = x) || true) && (!_tmp_.nil? || nil) && _tmp_.y
        # This allows us to handle `false&.to_s == "false"`
        def safe_navigation(node)
          s(:begin,
            s(:and,
              s(:begin,
                s(:or,
                  s(:begin, s(:lvasgn, SAFE_LVAR, node)),
                  s(:true))),
              s(:begin,
                s(:or,
                  s(:send,
                    s(:send, safe_lvar, :nil?),
                    :!),
                  s(:nil)))))
        end

        def safe_lvar
          s(:lvar, SAFE_LVAR)
        end
      end
    end
  end
end
