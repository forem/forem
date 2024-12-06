# frozen_string_literal: true

module RubyNext
  module Language
    module Rewriters
      class RequiredKwargs < Base
        using RubyNext

        NAME = "required-kwargs"
        SYNTAX_PROBE = "obj = Object.new; def obj.foo(x:, y: 1); end"
        MIN_SUPPORTED_VERSION = Gem::Version.new("2.1.0")

        def on_kwarg(node)
          context.track! self

          name = node.children[0]

          new_node = node.updated(
            :kwoptarg,
            [name, raise_missing_keyword(name)]
          )

          replace(node.loc.expression, "#{name}: ::Kernel.raise(::ArgumentError, \"missing keyword: #{name}\")")

          new_node
        end

        private

        def raise_missing_keyword(name)
          s(:send,
            s(:const, s(:cbase), :Kernel), :raise,
            s(:const, s(:cbase), :ArgumentError),
            s(:str, "missing keyword: #{name}"))
        end
      end
    end
  end
end
