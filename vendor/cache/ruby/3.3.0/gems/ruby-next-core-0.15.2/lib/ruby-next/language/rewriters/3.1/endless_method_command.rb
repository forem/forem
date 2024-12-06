# frozen_string_literal: true

module RubyNext
  module Language
    module Rewriters
      class EndlessMethodCommand < EndlessMethod
        NAME = "endless-method-command"
        SYNTAX_PROBE = "obj = Object.new; def obj.foo = puts 'Hello'"
        MIN_SUPPORTED_VERSION = Gem::Version.new("3.1.0")

        def process_def(node)
          return node unless command?(node)

          super(node)
        end

        def process_defs(node)
          return node unless command?(node)

          super(node)
        end

        private

        def command?(node)
          buffer = ::Parser::Source::Buffer.new("(endless-method-rewriter)").tap do |buffer|
            buffer.source = node.loc.expression.source
          end

          parser30.parse(buffer)
          false
        rescue ::Parser::SyntaxError
          true
        end

        def parser30
          require "parser/ruby30" unless defined?(::Parser::Ruby30)

          ::Parser::Ruby30.new(Language::Builder.new).tap do |prs|
            prs.diagnostics.all_errors_are_fatal = true
          end
        end
      end
    end
  end
end
