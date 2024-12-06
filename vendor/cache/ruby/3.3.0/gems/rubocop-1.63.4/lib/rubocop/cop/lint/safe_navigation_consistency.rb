# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Check to make sure that if safe navigation is used for a method
      # call in an `&&` or `||` condition that safe navigation is used for all
      # method calls on that same object.
      #
      # @example
      #   # bad
      #   foo&.bar && foo.baz
      #
      #   # bad
      #   foo.bar || foo&.baz
      #
      #   # bad
      #   foo&.bar && (foobar.baz || foo.baz)
      #
      #   # good
      #   foo.bar && foo.baz
      #
      #   # good
      #   foo&.bar || foo&.baz
      #
      #   # good
      #   foo&.bar && (foobar.baz || foo&.baz)
      #
      class SafeNavigationConsistency < Base
        include IgnoredNode
        include NilMethods
        extend AutoCorrector

        MSG = 'Ensure that safe navigation is used consistently inside of `&&` and `||`.'

        def on_csend(node)
          return unless node.parent&.operator_keyword?

          check(node)
        end

        def check(node)
          ancestor = top_conditional_ancestor(node)
          conditions = ancestor.conditions
          safe_nav_receiver = node.receiver

          method_calls = conditions.select(&:send_type?)
          unsafe_method_calls = unsafe_method_calls(method_calls, safe_nav_receiver)

          unsafe_method_calls.each do |unsafe_method_call|
            location = location(node, unsafe_method_call)

            add_offense(location) { |corrector| autocorrect(corrector, unsafe_method_call) }

            ignore_node(unsafe_method_call)
          end
        end

        private

        def autocorrect(corrector, node)
          return unless node.dot?

          corrector.insert_before(node.loc.dot, '&')
        end

        def location(node, unsafe_method_call)
          node.source_range.join(unsafe_method_call.source_range)
        end

        def top_conditional_ancestor(node)
          parent = node.parent
          unless parent &&
                 (parent.operator_keyword? ||
                  (parent.begin_type? && parent.parent && parent.parent.operator_keyword?))
            return node
          end

          top_conditional_ancestor(parent)
        end

        def unsafe_method_calls(method_calls, safe_nav_receiver)
          method_calls.select do |method_call|
            safe_nav_receiver == method_call.receiver &&
              !nil_methods.include?(method_call.method_name) &&
              !ignored_node?(method_call)
          end
        end
      end
    end
  end
end
