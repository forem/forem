# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for setter call to local variable as the final
      # expression of a function definition.
      #
      # @safety
      #   There are edge cases in which the local variable references a
      #   value that is also accessible outside the local scope. This is not
      #   detected by the cop, and it can yield a false positive.
      #
      #   As well, autocorrection is unsafe because the method's
      #   return value will be changed.
      #
      # @example
      #
      #   # bad
      #
      #   def something
      #     x = Something.new
      #     x.attr = 5
      #   end
      #
      # @example
      #
      #   # good
      #
      #   def something
      #     x = Something.new
      #     x.attr = 5
      #     x
      #   end
      class UselessSetterCall < Base
        extend AutoCorrector

        MSG = 'Useless setter call to local variable `%<variable>s`.'
        ASSIGNMENT_TYPES = %i[lvasgn ivasgn cvasgn gvasgn].freeze

        def on_def(node)
          return unless node.body

          last_expr = last_expression(node.body)
          return unless setter_call_to_local_variable?(last_expr)

          tracker = MethodVariableTracker.new(node.body)
          receiver, = *last_expr
          variable_name, = *receiver
          return unless tracker.contain_local_object?(variable_name)

          loc_name = receiver.loc.name

          add_offense(loc_name, message: format(MSG, variable: loc_name.source)) do |corrector|
            corrector.insert_after(last_expr, "\n#{indent(last_expr)}#{loc_name.source}")
          end
        end
        alias on_defs on_def

        private

        # @!method setter_call_to_local_variable?(node)
        def_node_matcher :setter_call_to_local_variable?, <<~PATTERN
          [(send (lvar _) ...) setter_method?]
        PATTERN

        def last_expression(body)
          expression = body.begin_type? ? body.children : body

          expression.is_a?(Array) ? expression.last : expression
        end

        # This class tracks variable assignments in a method body
        # and if a variable contains object passed as argument at the end of
        # the method.
        class MethodVariableTracker
          def initialize(body_node)
            @body_node = body_node
            @local = nil
          end

          def contain_local_object?(variable_name)
            return @local[variable_name] if @local

            @local = {}

            scan(@body_node) { |node| process_assignment_node(node) }

            @local[variable_name]
          end

          def scan(node, &block)
            catch(:skip_children) do
              yield node

              node.each_child_node { |child_node| scan(child_node, &block) }
            end
          end

          def process_assignment_node(node)
            case node.type
            when :masgn
              process_multiple_assignment(node)
            when :or_asgn, :and_asgn
              process_logical_operator_assignment(node)
            when :op_asgn
              process_binary_operator_assignment(node)
            when *ASSIGNMENT_TYPES
              _, rhs_node = *node
              process_assignment(node, rhs_node) if rhs_node
            end
          end

          def process_multiple_assignment(masgn_node)
            mlhs_node, mrhs_node = *masgn_node

            mlhs_node.children.each_with_index do |lhs_node, index|
              next unless ASSIGNMENT_TYPES.include?(lhs_node.type)

              lhs_variable_name, = *lhs_node
              rhs_node = mrhs_node.children[index]

              if mrhs_node.array_type? && rhs_node
                process_assignment(lhs_variable_name, rhs_node)
              else
                @local[lhs_variable_name] = true
              end
            end

            throw :skip_children
          end

          def process_logical_operator_assignment(asgn_node)
            lhs_node, rhs_node = *asgn_node
            return unless ASSIGNMENT_TYPES.include?(lhs_node.type)

            process_assignment(lhs_node, rhs_node)

            throw :skip_children
          end

          def process_binary_operator_assignment(op_asgn_node)
            lhs_node, = *op_asgn_node
            return unless ASSIGNMENT_TYPES.include?(lhs_node.type)

            lhs_variable_name, = *lhs_node
            @local[lhs_variable_name] = true

            throw :skip_children
          end

          def process_assignment(asgn_node, rhs_node)
            lhs_variable_name, = *asgn_node

            @local[lhs_variable_name] = if rhs_node.variable?
                                          rhs_variable_name, = *rhs_node
                                          @local[rhs_variable_name]
                                        else
                                          constructor?(rhs_node)
                                        end
          end

          def constructor?(node)
            return true if node.literal?
            return false unless node.send_type?

            node.method?(:new)
          end
        end
      end
    end
  end
end
