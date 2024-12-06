# frozen_string_literal: true

module RubyNext
  module Language
    module Rewriters
      class ShorthandHash < Base
        NAME = "shorthand-hash"
        SYNTAX_PROBE = "data = {x:}"
        MIN_SUPPORTED_VERSION = Gem::Version.new("3.1.0")

        def on_pair(node)
          return super(node) unless node.children[0].loc.last_column == node.children[1].loc.last_column

          context.track! self

          _, ident, = *node.children

          key = key_from_ident(ident)

          replace(
            node.loc.expression,
            "#{key}: #{key}"
          )

          node.updated(
            :pair,
            [
              s(:sym, key),
              ident
            ]
          )
        end

        private

        def key_from_ident(node)
          case node.type
          when :send
            node.children[1]
          when :lvar
            node.children[0]
          else
            raise ArgumentError, "Unsupport ipair node: #{node}"
          end
        end
      end
    end
  end
end
