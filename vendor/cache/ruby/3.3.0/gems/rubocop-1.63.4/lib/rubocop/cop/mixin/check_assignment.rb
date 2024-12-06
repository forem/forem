# frozen_string_literal: true

module RuboCop
  module Cop
    # Common functionality for checking assignment nodes.
    module CheckAssignment
      def on_lvasgn(node)
        check_assignment(node, extract_rhs(node))
      end
      alias on_ivasgn   on_lvasgn
      alias on_cvasgn   on_lvasgn
      alias on_gvasgn   on_lvasgn
      alias on_casgn    on_lvasgn
      alias on_masgn    on_lvasgn
      alias on_op_asgn  on_lvasgn
      alias on_or_asgn  on_lvasgn
      alias on_and_asgn on_lvasgn

      def on_send(node)
        rhs = extract_rhs(node)

        return unless rhs

        check_assignment(node, rhs)
      end

      module_function

      def extract_rhs(node)
        if node.casgn_type?
          _scope, _lhs, rhs = *node
        elsif node.op_asgn_type?
          _lhs, _op, rhs = *node
        elsif node.call_type?
          rhs = node.last_argument
        elsif node.assignment?
          _lhs, rhs = *node
        end

        rhs
      end
    end
  end
end
