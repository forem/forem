# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for unreachable code.
      # The check are based on the presence of flow of control
      # statement in non-final position in `begin` (implicit) blocks.
      #
      # @example
      #
      #   # bad
      #
      #   def some_method
      #     return
      #     do_something
      #   end
      #
      #   # bad
      #
      #   def some_method
      #     if cond
      #       return
      #     else
      #       return
      #     end
      #     do_something
      #   end
      #
      # @example
      #
      #   # good
      #
      #   def some_method
      #     do_something
      #   end
      class UnreachableCode < Base
        MSG = 'Unreachable code detected.'

        def on_begin(node)
          expressions = *node

          expressions.each_cons(2) do |expression1, expression2|
            next unless flow_expression?(expression1)

            add_offense(expression2)
          end
        end

        alias on_kwbegin on_begin

        private

        # @!method flow_command?(node)
        def_node_matcher :flow_command?, <<~PATTERN
          {
            return next break retry redo
            (send
             {nil? (const {nil? cbase} :Kernel)}
             {:raise :fail :throw :exit :exit! :abort}
             ...)
          }
        PATTERN

        def flow_expression?(node)
          return true if flow_command?(node)

          case node.type
          when :begin, :kwbegin
            expressions = *node
            expressions.any? { |expr| flow_expression?(expr) }
          when :if
            check_if(node)
          when :case, :case_match
            check_case(node)
          else
            false
          end
        end

        def check_if(node)
          if_branch = node.if_branch
          else_branch = node.else_branch
          if_branch && else_branch && flow_expression?(if_branch) && flow_expression?(else_branch)
        end

        def check_case(node)
          else_branch = node.else_branch
          return false unless else_branch
          return false unless flow_expression?(else_branch)

          branches = node.case_type? ? node.when_branches : node.in_pattern_branches

          branches.all? { |branch| branch.body && flow_expression?(branch.body) }
        end
      end
    end
  end
end
