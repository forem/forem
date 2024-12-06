# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for places where redundant assignments are made for in place
      # modification methods.
      #
      # @safety
      #   This cop is unsafe, because it can produce false positives for
      #   user defined methods having one of the expected names, but not modifying
      #   its receiver in place.
      #
      # @example
      #   # bad
      #   args = args.concat(ary)
      #   hash = hash.merge!(other)
      #
      #   # good
      #   args.concat(foo)
      #   args += foo
      #   hash.merge!(other)
      #
      #   # bad
      #   self.foo = foo.concat(ary)
      #
      #   # good
      #   foo.concat(ary)
      #   self.foo += ary
      #
      class RedundantSelfAssignment < Base
        include RangeHelp
        extend AutoCorrector

        MSG = 'Redundant self assignment detected. ' \
              'Method `%<method_name>s` modifies its receiver in place.'

        METHODS_RETURNING_SELF = %i[
          append clear collect! compare_by_identity concat delete_if
          fill initialize_copy insert keep_if map! merge! prepend push
          rehash replace reverse! rotate! shuffle! sort! sort_by!
          transform_keys! transform_values! unshift update
        ].to_set.freeze

        ASSIGNMENT_TYPE_TO_RECEIVER_TYPE = {
          lvasgn: :lvar,
          ivasgn: :ivar,
          cvasgn: :cvar,
          gvasgn: :gvar
        }.freeze

        def on_lvasgn(node)
          lhs, rhs = *node
          receiver, method_name, = *rhs
          return unless receiver && method_returning_self?(method_name)

          receiver_type = ASSIGNMENT_TYPE_TO_RECEIVER_TYPE[node.type]
          return unless receiver.type == receiver_type && receiver.children.first == lhs

          message = format(MSG, method_name: method_name)
          add_offense(node.loc.operator, message: message) do |corrector|
            corrector.replace(node, rhs.source)
          end
        end
        alias on_ivasgn on_lvasgn
        alias on_cvasgn on_lvasgn
        alias on_gvasgn on_lvasgn

        def on_send(node)
          return unless node.assignment_method?
          return unless redundant_assignment?(node)

          message = format(MSG, method_name: node.first_argument.method_name)
          add_offense(node.loc.operator, message: message) do |corrector|
            corrector.remove(correction_range(node))
          end
        end

        private

        def method_returning_self?(method_name)
          METHODS_RETURNING_SELF.include?(method_name)
        end

        # @!method redundant_self_assignment?(node, method_name)
        def_node_matcher :redundant_self_assignment?, <<~PATTERN
          (send
            (self) _
            (send
              (send
                {(self) nil?} %1) #method_returning_self?
              ...))
        PATTERN

        # @!method redundant_nonself_assignment?(node, receiver, method_name)
        def_node_matcher :redundant_nonself_assignment?, <<~PATTERN
          (send
            %1 _
            (send
              (send
                %1 %2) #method_returning_self?
              ...))
        PATTERN

        def redundant_assignment?(node)
          receiver_name = node.method_name.to_s[0...-1].to_sym

          redundant_self_assignment?(node, receiver_name) ||
            redundant_nonself_assignment?(node, node.receiver, receiver_name)
        end

        def correction_range(node)
          range_between(node.source_range.begin_pos, node.first_argument.source_range.begin_pos)
        end
      end
    end
  end
end
