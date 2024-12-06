# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for `raise` or `fail` statements which are
      # raising `Exception` class.
      #
      # You can specify a module name that will be an implicit namespace
      # using `AllowedImplicitNamespaces` option. The cop cause a false positive
      # for namespaced `Exception` when a namespace is omitted. This option can
      # prevent the false positive by specifying a namespace to be omitted for
      # `Exception`. Alternatively, make `Exception` a fully qualified class
      # name with an explicit namespace.
      #
      # @safety
      #   This cop is unsafe because it will change the exception class being
      #   raised, which is a change in behavior.
      #
      # @example
      #   # bad
      #   raise Exception, 'Error message here'
      #
      #   # good
      #   raise StandardError, 'Error message here'
      #
      # @example AllowedImplicitNamespaces: ['Gem']
      #   # good
      #   module Gem
      #     def self.foo
      #       raise Exception # This exception means `Gem::Exception`.
      #     end
      #   end
      class RaiseException < Base
        extend AutoCorrector

        MSG = 'Use `StandardError` over `Exception`.'
        RESTRICT_ON_SEND = %i[raise fail].freeze

        # @!method exception?(node)
        def_node_matcher :exception?, <<~PATTERN
          (send nil? {:raise :fail} $(const ${cbase nil?} :Exception) ... )
        PATTERN

        # @!method exception_new_with_message?(node)
        def_node_matcher :exception_new_with_message?, <<~PATTERN
          (send nil? {:raise :fail}
            (send $(const ${cbase nil?} :Exception) :new ... ))
        PATTERN

        def on_send(node)
          exception?(node, &check(node)) || exception_new_with_message?(node, &check(node))
        end

        private

        def check(node)
          lambda do |exception_class, cbase|
            return if cbase.nil? && implicit_namespace?(node)

            add_offense(exception_class) do |corrector|
              prefer_exception = if exception_class.children.first&.cbase_type?
                                   '::StandardError'
                                 else
                                   'StandardError'
                                 end

              corrector.replace(exception_class, prefer_exception)
            end
          end
        end

        def implicit_namespace?(node)
          return false unless (parent = node.parent)

          if parent.module_type?
            namespace = parent.identifier.source

            return allow_implicit_namespaces.include?(namespace)
          end

          implicit_namespace?(parent)
        end

        def allow_implicit_namespaces
          cop_config['AllowedImplicitNamespaces'] || []
        end
      end
    end
  end
end
