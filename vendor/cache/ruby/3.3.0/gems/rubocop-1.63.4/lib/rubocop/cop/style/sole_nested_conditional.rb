# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # If the branch of a conditional consists solely of a conditional node,
      # its conditions can be combined with the conditions of the outer branch.
      # This helps to keep the nesting level from getting too deep.
      #
      # @example
      #   # bad
      #   if condition_a
      #     if condition_b
      #       do_something
      #     end
      #   end
      #
      #   # bad
      #   if condition_b
      #     do_something
      #   end if condition_a
      #
      #   # good
      #   if condition_a && condition_b
      #     do_something
      #   end
      #
      # @example AllowModifier: false (default)
      #   # bad
      #   if condition_a
      #     do_something if condition_b
      #   end
      #
      #   # bad
      #   if condition_b
      #     do_something
      #   end if condition_a
      #
      # @example AllowModifier: true
      #   # good
      #   if condition_a
      #     do_something if condition_b
      #   end
      #
      #   # good
      #   if condition_b
      #     do_something
      #   end if condition_a
      class SoleNestedConditional < Base
        include RangeHelp
        extend AutoCorrector

        MSG = 'Consider merging nested conditions into outer `%<conditional_type>s` conditions.'

        def self.autocorrect_incompatible_with
          [Style::NegatedIf, Style::NegatedUnless]
        end

        def on_if(node)
          return if node.ternary? || node.else? || node.elsif?

          if_branch = node.if_branch
          return if use_variable_assignment_in_condition?(node.condition, if_branch)
          return unless offending_branch?(node, if_branch)

          message = format(MSG, conditional_type: node.keyword)
          add_offense(if_branch.loc.keyword, message: message) do |corrector|
            autocorrect(corrector, node, if_branch)
          end
        end

        private

        def use_variable_assignment_in_condition?(condition, if_branch)
          assigned_variables = assigned_variables(condition)

          assigned_variables && if_branch&.if_type? &&
            assigned_variables.include?(if_branch.condition.source)
        end

        def assigned_variables(condition)
          assigned_variables = condition.assignment? ? [condition.children.first.to_s] : []

          assigned_variables + condition.descendants.select(&:assignment?).map do |node|
            node.children.first.to_s
          end
        end

        def offending_branch?(node, branch)
          return false unless branch

          branch.if_type? &&
            !branch.else? &&
            !branch.ternary? &&
            !((node.modifier_form? || branch.modifier_form?) && allow_modifier?)
        end

        def autocorrect(corrector, node, if_branch)
          if node.condition.or_type? || node.condition.assignment?
            corrector.wrap(node.condition, '(', ')')
          end

          if outer_condition_modify_form?(node, if_branch)
            autocorrect_outer_condition_modify_form(corrector, node, if_branch)
          else
            autocorrect_outer_condition_basic(corrector, node, if_branch)
          end
        end

        def autocorrect_outer_condition_basic(corrector, node, if_branch)
          correct_from_unless_to_if(corrector, node) if node.unless?

          outer_condition = node.condition
          correct_outer_condition(corrector, outer_condition)

          and_operator = if_branch.unless? ? ' && !' : ' && '
          if if_branch.modifier_form?
            correct_for_guard_condition_style(corrector, outer_condition, if_branch, and_operator)
          else
            correct_for_basic_condition_style(corrector, node, if_branch, and_operator)
            correct_for_comment(corrector, node, if_branch)
          end
        end

        def autocorrect_outer_condition_modify_form(corrector, node, if_branch)
          correct_from_unless_to_if(corrector, if_branch, is_modify_form: true) if if_branch.unless?
          correct_for_outer_condition_modify_form_style(corrector, node, if_branch)
        end

        def correct_from_unless_to_if(corrector, node, is_modify_form: false)
          corrector.replace(node.loc.keyword, 'if')

          insert_bang(corrector, node, is_modify_form)
        end

        def correct_for_guard_condition_style(corrector, outer_condition, if_branch, and_operator)
          condition = if_branch.condition
          corrector.insert_after(outer_condition, "#{and_operator}#{replace_condition(condition)}")

          range = range_between(if_branch.loc.keyword.begin_pos, condition.source_range.end_pos)
          corrector.remove(range_with_surrounding_space(range, newlines: false))
          corrector.remove(if_branch.loc.keyword)
        end

        def correct_for_basic_condition_style(corrector, node, if_branch, and_operator)
          range = range_between(
            node.condition.source_range.end_pos, if_branch.condition.source_range.begin_pos
          )
          corrector.replace(range, and_operator)
          corrector.remove(range_by_whole_lines(node.loc.end, include_final_newline: true))

          wrap_condition(corrector, if_branch.condition)
        end

        def wrap_condition(corrector, condition)
          # Handle `send` and `block` nodes that need to be wrapped in parens
          # FIXME: autocorrection prevents syntax errors by wrapping the entire node in parens,
          #        but wrapping the argument list would be a more ergonomic correction.
          node_to_check = condition&.block_type? ? condition.send_node : condition
          return unless wrap_condition?(node_to_check)

          corrector.wrap(condition, '(', ')')
        end

        def correct_for_outer_condition_modify_form_style(corrector, node, if_branch)
          condition = if_branch.condition
          corrector.insert_before(condition,
                                  "#{'!' if node.unless?}#{replace_condition(node.condition)} && ")

          corrector.remove(node.condition)
          corrector.remove(range_with_surrounding_space(node.loc.keyword, newlines: false))
          corrector.replace(if_branch.loc.keyword, 'if')
        end

        def correct_for_comment(corrector, node, if_branch)
          comments = processed_source.ast_with_comments[if_branch].select do |comment|
            comment.loc.line < if_branch.condition.first_line
          end
          comment_text = comments.map(&:text).join("\n") << "\n"

          corrector.insert_before(node.loc.keyword, comment_text) unless comments.empty?
        end

        def correct_outer_condition(corrector, condition)
          return unless require_parentheses?(condition)

          end_pos = condition.loc.selector.end_pos
          begin_pos = condition.first_argument.source_range.begin_pos
          return if end_pos > begin_pos

          range = range_between(end_pos, begin_pos)
          corrector.remove(range)
          corrector.insert_after(range, '(')
          corrector.insert_after(condition.last_argument, ')')
        end

        def insert_bang(corrector, node, is_modify_form)
          condition = node.condition

          if (condition.send_type? && condition.comparison_method? && !condition.parenthesized?) ||
             (is_modify_form && wrap_condition?(condition))
            corrector.wrap(node.condition, '!(', ')')
          elsif condition.and_type?
            insert_bang_for_and(corrector, node)
          else
            corrector.insert_before(condition, '!')
          end
        end

        def insert_bang_for_and(corrector, node)
          lhs, rhs = *node

          if lhs.and_type?
            insert_bang_for_and(corrector, lhs)
            corrector.insert_before(rhs, '!') if rhs
          else
            corrector.insert_before(lhs, '!')
            corrector.insert_before(rhs, '!')
          end
        end

        def require_parentheses?(condition)
          condition.call_type? && !condition.arguments.empty? && !condition.parenthesized? &&
            !condition.comparison_method?
        end

        def arguments_range(node)
          range_between(
            node.first_argument.source_range.begin_pos, node.last_argument.source_range.end_pos
          )
        end

        def wrap_condition?(node)
          node.and_type? || node.or_type? ||
            (node.call_type? && node.arguments.any? && !node.parenthesized?)
        end

        def replace_condition(condition)
          wrap_condition?(condition) ? "(#{condition.source})" : condition.source
        end

        def allow_modifier?
          cop_config['AllowModifier']
        end

        def outer_condition_modify_form?(node, if_branch)
          node.condition.source_range.begin_pos > if_branch.condition.source_range.begin_pos
        end
      end
    end
  end
end
