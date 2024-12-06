# frozen_string_literal: true

module RubyNext
  module Language
    module Rewriters
      class MethodReference < Base
        NAME = "method-reference"
        SYNTAX_PROBE = "Language.:transform"
        MIN_SUPPORTED_VERSION = Gem::Version.new(RubyNext::NEXT_VERSION)

        def on_meth_ref(node)
          context.track! self

          receiver, mid = *node.children

          replace(
            node.children.first.loc.expression.end.join(
              node.loc.expression.end
            ),
            ".method(:#{mid})"
          )

          node.updated(
            :send,
            [
              receiver,
              :method,
              s(:sym, mid)
            ]
          )
        end
      end
    end
  end
end
