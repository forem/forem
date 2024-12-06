# frozen_string_literal: true

module RubyNext
  module Language
    module Rewriters
      class EndlessMethod < Base
        NAME = "endless-method"
        SYNTAX_PROBE = "obj = Object.new; def obj.foo() = 42"
        MIN_SUPPORTED_VERSION = Gem::Version.new("3.0.0")

        def on_def(node)
          return process_def(node) if endless?(node)

          super(node)
        end

        def process_def(node)
          context.track! self

          replace(node.loc.assignment, "; ")
          insert_after(node.loc.expression, "; end")

          new_loc = node.loc.dup
          new_loc.instance_variable_set(:@end, node.loc.expression)

          process(
            node.updated(
              :def,
              node.children,
              location: new_loc
            )
          )
        end

        def on_defs(node)
          return process_defs(node) if endless?(node)
          super(node)
        end

        def process_defs(node)
          context.track! self

          replace(node.loc.assignment, "; ")
          insert_after(node.loc.expression, "; end")

          new_loc = node.loc.dup
          new_loc.instance_variable_set(:@end, node.loc.expression)

          process(
            node.updated(
              :defs,
              node.children,
              location: new_loc
            )
          )
        end

        private

        def endless?(node)
          node.loc.end.nil?
        end
      end
    end
  end
end
