# frozen_string_literal: true

module RubyNext
  module Language
    module Rewriters
      class EndlessRange < Base
        NAME = "endless-range"
        SYNTAX_PROBE = "[0, 1][1..]"
        MIN_SUPPORTED_VERSION = Gem::Version.new("2.6.0")

        def on_index(node)
          @current_index = node
          new_index = process(node.children.last)
          return unless new_index != node.children.last

          node.updated(
            nil,
            [
              node.children.first,
              new_index
            ]
          )
        end

        def on_erange(node)
          return unless node.children.last.nil?

          context.track! self

          new_end =
            if index_arg?(node)
              s(:int, -1)
            else
              s(:const,
                s(:const,
                  s(:cbase), :Float),
                :INFINITY)
            end

          replace(node.loc.expression, "#{node.children.first.loc.expression.source}..#{unparse(new_end)}")

          node.updated(
            :irange,
            [
              node.children.first,
              new_end
            ]
          )
        end

        alias_method :on_irange, :on_erange

        private

        attr_reader :current_index

        def index_arg?(node)
          ((((__safe_lvar__ = ((((__safe_lvar__ = current_index) || true) && (!__safe_lvar__.nil? || nil)) && __safe_lvar__.children)) || true) && (!__safe_lvar__.nil? || nil)) && __safe_lvar__.include?(node))
        end
      end
    end
  end
end
