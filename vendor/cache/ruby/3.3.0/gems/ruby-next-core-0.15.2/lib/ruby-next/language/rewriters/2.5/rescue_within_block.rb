# frozen_string_literal: true

module RubyNext
  module Language
    module Rewriters
      class RescueWithinBlock < Base
        NAME = "rescue-within-block"
        SYNTAX_PROBE = "lambda do
          raise 'err'
        rescue
          $! # => #<RuntimeError: err>
        end.call"

        MIN_SUPPORTED_VERSION = Gem::Version.new("2.5.0")

        def on_block(block_node)
          exception_node = block_node.children.find do |node|
            node && (node.type == :rescue || node.type == :ensure)
          end

          return super(block_node) unless exception_node

          context.track! self

          insert_before(exception_node.loc.expression, "begin;")
          insert_after(exception_node.loc.expression, ";end")

          new_children = block_node.children.map do |child|
            next s(:kwbegin, exception_node) if child == exception_node

            child
          end

          process(
            block_node.updated(:block, new_children)
          )
        end
      end
    end
  end
end
