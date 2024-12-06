# frozen_string_literal: true

# Add binding argument to all self-less eval's
module RubyNext
  module Language
    module Rewriters
      class RefinementImportMethods < Language::Rewriters::Base
        NAME = "refinement-import-methods"
        SYNTAX_PROBE = "a = Module.new{}; Module.new do; refine String do; import_methods a end; end"
        MIN_SUPPORTED_VERSION = Gem::Version.new("3.1.0")

        def on_block(node)
          sender, args, body = *node
          receiver, mid, * = *sender

          return super unless mid == :refine && receiver.nil?

          return super unless body

          @within_refinement = true

          node.updated(
            nil,
            [
              sender,
              args,
              process(body)
            ]
          ).tap do
            @within_refinement = false
          end
        end

        def on_send(node)
          return super unless @within_refinement

          _receiver, mid, *children = *node

          return super unless mid == :import_methods

          context.track! self

          updated = node.updated(
            nil,
            [
              s(:const, s(:const, s(:cbase), :RubyNext), :Core),
              mid,
              *children,
              s(:send, nil, :binding)
            ]
          )

          replace(node.loc.expression, updated)

          updated
        end
      end
    end
  end
end
