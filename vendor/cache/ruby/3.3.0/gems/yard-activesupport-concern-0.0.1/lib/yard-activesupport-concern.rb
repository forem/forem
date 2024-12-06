require 'yard-activesupport-concern/version'
require 'yard'

module YARD
  module ActiveSupport
    module Concern

      class IncludedHandler < YARD::Handlers::Ruby::Base
        handles method_call(:included)
        namespace_only

        # Process any found `included` block within a "namespace" scope (class
        # or module).
        def process
          # `statement.last.last` refers to the statements within the block
          # given to `included`. YARD will parse those and attach any generated
          # documentation to the current namespace at the instance level (unless
          # overridden with a @!scope directive)
          parse_block(statement.last.last, namespace: namespace, scope: :instance)
        end
      end

      class ClassMethodsHandler < YARD::Handlers::Ruby::Base
        handles method_call(:class_methods)
        namespace_only

        # Process any found `class_methods` block within a "namespace" scope
        # (class or module).
        def process
          # `statement.last.last` refers to the statements within the block
          # given to `class_methods`. YARD will parse those and attach any
          # generated documentation to the current namespace at the class
          # level (unless overridden with a @!scope directive)
          parse_block(statement.last.last, namespace: namespace, scope: :class)
        end
      end

    end
  end
end
