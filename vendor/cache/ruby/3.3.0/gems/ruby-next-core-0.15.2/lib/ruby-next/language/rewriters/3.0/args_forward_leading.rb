# frozen_string_literal: true

module RubyNext
  module Language
    module Rewriters
      class ArgsForwardLeading < ArgsForward
        NAME = "args-forward-leading"
        SYNTAX_PROBE = "obj = Object.new; def obj.foo(...) super(1, ...); end"
        MIN_SUPPORTED_VERSION = Gem::Version.new("3.0.0")

        attr_reader :leading_farg
        alias leading_farg? leading_farg

        def on_def(node)
          @leading_farg = method_with_leading_arg(node)

          super
        end

        def on_defs(node)
          @leading_farg = method_with_leading_arg(node)

          super
        end

        def on_args(node)
          return super if leading_farg?

          node
        end

        def on_send(node)
          return super if leading_farg?

          node
        end

        def on_super(node)
          return super if leading_farg?

          node
        end

        private

        def send_with_leading_farg(node)
          return false unless node.type == :send || node.type == :super

          fargs = extract_fargs(node)

          return false unless fargs

          node.children.index(fargs) > (node.type == :send ? 2 : 0)
        end

        def method_with_leading_arg(node)
          find_child(node) { |child| child.type == :forward_arg } &&
            (
              def_with_leading_farg(node) ||
              find_child(node) { |child| send_with_leading_farg(child) }
            )
        end

        def def_with_leading_farg(node)
          args = node.type == :defs ? node.children[2] : node.children[1]
          args = args.children

          farg = args.detect { |child| child.type == :forward_arg }

          args.index(farg) > 0
        end
      end
    end
  end
end
