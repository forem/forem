# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks if `return` or `return nil` is used in predicate method definitions.
      #
      # @safety
      #   Autocorrection is marked as unsafe because the change of the return value
      #   from `nil` to `false` could potentially lead to incompatibility issues.
      #
      # @example
      #   # bad
      #   def foo?
      #     return if condition
      #
      #     do_something?
      #   end
      #
      #   # bad
      #   def foo?
      #     return nil if condition
      #
      #     do_something?
      #   end
      #
      #   # good
      #   def foo?
      #     return false if condition
      #
      #     do_something?
      #   end
      #
      # @example AllowedMethods: ['foo?']
      #   # good
      #   def foo?
      #     return if condition
      #
      #     do_something?
      #   end
      #
      # @example AllowedPatterns: [/foo/]
      #   # good
      #   def foo?
      #     return if condition
      #
      #     do_something?
      #   end
      #
      class ReturnNilInPredicateMethodDefinition < Base
        extend AutoCorrector
        include AllowedMethods
        include AllowedPattern

        MSG = 'Return `false` instead of `nil` in predicate methods.'

        # @!method return_nil?(node)
        def_node_matcher :return_nil?, <<~PATTERN
          {(return) (return (nil))}
        PATTERN

        def on_def(node)
          return unless node.predicate_method?
          return if allowed_method?(node.method_name) || matches_allowed_pattern?(node.method_name)
          return unless (body = node.body)

          body.each_descendant(:return) do |return_node|
            register_offense(return_node, 'return false') if return_nil?(return_node)
          end

          return unless (nil_node = nil_node_at_the_end_of_method_body(body))

          register_offense(nil_node, 'false')
        end
        alias on_defs on_def

        private

        def nil_node_at_the_end_of_method_body(body)
          return body if body.nil_type?
          return unless body.begin_type?
          return unless (last_child = body.children.last)

          last_child if last_child.is_a?(AST::Node) && last_child.nil_type?
        end

        def register_offense(offense_node, replacement)
          add_offense(offense_node) do |corrector|
            corrector.replace(offense_node, replacement)
          end
        end
      end
    end
  end
end
