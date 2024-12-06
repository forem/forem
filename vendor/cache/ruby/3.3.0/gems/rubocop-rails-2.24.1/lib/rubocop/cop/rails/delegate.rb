# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Looks for delegations that could have been created
      # automatically with the `delegate` method.
      #
      # Safe navigation `&.` is ignored because Rails' `allow_nil`
      # option checks not just for nil but also delegates if nil
      # responds to the delegated method.
      #
      # The `EnforceForPrefixed` option (defaulted to `true`) means that
      # using the target object as a prefix of the method name
      # without using the `delegate` method will be a violation.
      # When set to `false`, this case is legal.
      #
      # @example
      #   # bad
      #   def bar
      #     foo.bar
      #   end
      #
      #   # good
      #   delegate :bar, to: :foo
      #
      #   # bad
      #   def bar
      #     self.bar
      #   end
      #
      #   # good
      #   delegate :bar, to: :self
      #
      #   # good
      #   def bar
      #     foo&.bar
      #   end
      #
      #   # good
      #   private
      #   def bar
      #     foo.bar
      #   end
      #
      # @example EnforceForPrefixed: true (default)
      #   # bad
      #   def foo_bar
      #     foo.bar
      #   end
      #
      #   # good
      #   delegate :bar, to: :foo, prefix: true
      #
      # @example EnforceForPrefixed: false
      #   # good
      #   def foo_bar
      #     foo.bar
      #   end
      #
      #   # good
      #   delegate :bar, to: :foo, prefix: true
      class Delegate < Base
        extend AutoCorrector
        include VisibilityHelp

        MSG = 'Use `delegate` to define delegations.'

        def_node_matcher :delegate?, <<~PATTERN
          (def _method_name _args
            (send {(send nil? _) (self)} _ ...))
        PATTERN

        def on_def(node)
          return unless trivial_delegate?(node)
          return if private_or_protected_delegation(node)

          register_offense(node)
        end

        private

        def register_offense(node)
          add_offense(node.loc.keyword) do |corrector|
            body = node.body

            receiver = body.receiver.self_type? ? 'self' : ":#{body.receiver.method_name}"

            delegation = ["delegate :#{body.method_name}", "to: #{receiver}"]
            delegation << ['prefix: true'] if node.method?(prefixed_method_name(node.body))

            corrector.replace(node, delegation.join(', '))
          end
        end

        def trivial_delegate?(def_node)
          delegate?(def_node) &&
            method_name_matches?(def_node.method_name, def_node.body) &&
            arguments_match?(def_node.arguments, def_node.body)
        end

        def arguments_match?(arg_array, body)
          argument_array = body.arguments

          return false if arg_array.size != argument_array.size

          arg_array.zip(argument_array).all? do |arg, argument|
            arg.arg_type? && argument.lvar_type? && arg.children == argument.children
          end
        end

        def method_name_matches?(method_name, body)
          method_name == body.method_name || (include_prefix_case? && method_name == prefixed_method_name(body))
        end

        def include_prefix_case?
          cop_config['EnforceForPrefixed']
        end

        def prefixed_method_name(body)
          return '' if body.receiver.self_type?

          [body.receiver.method_name, body.method_name].join('_').to_sym
        end

        def private_or_protected_delegation(node)
          private_or_protected_inline(node) || node_visibility(node) != :public
        end

        def private_or_protected_inline(node)
          processed_source[node.first_line - 1].strip.match?(/\A(private )|(protected )/)
        end
      end
    end
  end
end
