# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Enforces the use the shorthand for self-assignment.
      #
      # @example
      #
      #   # bad
      #   x = x + 1
      #
      #   # good
      #   x += 1
      class SelfAssignment < Base
        extend AutoCorrector

        MSG = 'Use self-assignment shorthand `%<method>s=`.'
        OPS = %i[+ - * ** / % ^ << >> | &].freeze

        def self.autocorrect_incompatible_with
          [Layout::SpaceAroundOperators]
        end

        def on_lvasgn(node)
          check(node, :lvar)
        end

        def on_ivasgn(node)
          check(node, :ivar)
        end

        def on_cvasgn(node)
          check(node, :cvar)
        end

        private

        def check(node, var_type)
          var_name, rhs = *node
          return unless rhs

          if rhs.send_type?
            check_send_node(node, rhs, var_name, var_type)
          elsif rhs.operator_keyword?
            check_boolean_node(node, rhs, var_name, var_type)
          end
        end

        def check_send_node(node, rhs, var_name, var_type)
          receiver, method_name, *_args = *rhs
          return unless OPS.include?(method_name)

          target_node = s(var_type, var_name)
          return unless receiver == target_node

          add_offense(node, message: format(MSG, method: method_name)) do |corrector|
            autocorrect(corrector, node)
          end
        end

        def check_boolean_node(node, rhs, var_name, var_type)
          first_operand, _second_operand = *rhs

          target_node = s(var_type, var_name)
          return unless first_operand == target_node

          operator = rhs.loc.operator.source
          add_offense(node, message: format(MSG, method: operator)) do |corrector|
            autocorrect(corrector, node)
          end
        end

        def autocorrect(corrector, node)
          _var_name, rhs = *node

          if rhs.send_type?
            autocorrect_send_node(corrector, node, rhs)
          elsif rhs.operator_keyword?
            autocorrect_boolean_node(corrector, node, rhs)
          end
        end

        def autocorrect_send_node(corrector, node, rhs)
          _receiver, method_name, args = *rhs
          apply_autocorrect(corrector, node, rhs, method_name.to_s, args)
        end

        def autocorrect_boolean_node(corrector, node, rhs)
          _first_operand, second_operand = *rhs
          apply_autocorrect(corrector, node, rhs, rhs.loc.operator.source, second_operand)
        end

        def apply_autocorrect(corrector, node, rhs, operator, new_rhs)
          corrector.insert_before(node.loc.operator, operator)
          corrector.replace(rhs, new_rhs.source)
        end
      end
    end
  end
end
