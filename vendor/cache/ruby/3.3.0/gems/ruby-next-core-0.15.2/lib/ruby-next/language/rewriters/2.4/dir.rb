# frozen_string_literal: true

module RubyNext
  module Language
    module Rewriters
      # Special rewriter for Ruby <=2.3, which doesn't support __dir__ in iseq.eval
      class Dir < Base
        SYNTAX_PROBE = "defined?(RubyVM::InstructionSequence) && RubyVM::InstructionSequence.compile('raise SyntaxError if __dir__.nil?', 'test.rb').eval"
        MIN_SUPPORTED_VERSION = Gem::Version.new("2.4.0")

        def on_send(node)
          return super(node) unless node.children[1] == :__dir__

          context.track! self

          replace(node.loc.expression, "File.dirname(__FILE__)")

          process(
            node.updated(
              nil,
              [
                s(:const, nil, :File),
                :dirname,
                s(:send, nil, "__FILE__")
              ]
            )
          )
        end
      end
    end
  end
end
