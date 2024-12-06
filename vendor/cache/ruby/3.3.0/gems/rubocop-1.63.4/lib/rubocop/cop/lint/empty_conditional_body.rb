# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for the presence of `if`, `elsif` and `unless` branches without a body.
      #
      # NOTE: empty `else` branches are handled by `Style/EmptyElse`.
      #
      # @safety
      #   Autocorrection for this cop is not safe. The conditions for empty branches that
      #   the autocorrection removes may have side effects, or the logic in subsequent
      #   branches may change due to the removal of a previous condition.
      #
      # @example
      #   # bad
      #   if condition
      #   end
      #
      #   # bad
      #   unless condition
      #   end
      #
      #   # bad
      #   if condition
      #     do_something
      #   elsif other_condition
      #   end
      #
      #   # good
      #   if condition
      #     do_something
      #   end
      #
      #   # good
      #   unless condition
      #     do_something
      #   end
      #
      #   # good
      #   if condition
      #     do_something
      #   elsif other_condition
      #     do_something_else
      #   end
      #
      # @example AllowComments: true (default)
      #   # good
      #   if condition
      #     do_something
      #   elsif other_condition
      #     # noop
      #   end
      #
      # @example AllowComments: false
      #   # bad
      #   if condition
      #     do_something
      #   elsif other_condition
      #     # noop
      #   end
      #
      class EmptyConditionalBody < Base
        extend AutoCorrector
        include CommentsHelp
        include RangeHelp

        MSG = 'Avoid `%<keyword>s` branches without a body.'

        def on_if(node)
          return if node.body || same_line?(node.loc.begin, node.loc.end)
          return if cop_config['AllowComments'] && contains_comments?(node)

          add_offense(node, message: format(MSG, keyword: node.keyword)) do |corrector|
            next if node.parent&.call_type?

            autocorrect(corrector, node)
          end
        end

        private

        def autocorrect(corrector, node)
          remove_comments(corrector, node)
          remove_empty_branch(corrector, node)
          correct_other_branches(corrector, node)
        end

        def remove_comments(corrector, node)
          comments_in_range(node).each do |comment|
            range = range_by_whole_lines(comment.source_range, include_final_newline: true)
            corrector.remove(range)
          end
        end

        def remove_empty_branch(corrector, node)
          if empty_if_branch?(node) && else_branch?(node)
            corrector.remove(branch_range(node))
          else
            corrector.remove(deletion_range(branch_range(node)))
          end
        end

        def correct_other_branches(corrector, node)
          return unless require_other_branches_correction?(node)

          if node.else_branch&.if_type? && !node.else_branch.modifier_form?
            # Replace an orphaned `elsif` with `if`
            corrector.replace(node.else_branch.loc.keyword, 'if')
          else
            # Flip orphaned `else`
            corrector.replace(node.loc.else, "#{node.inverse_keyword} #{node.condition.source}")
          end
        end

        def require_other_branches_correction?(node)
          return false unless node.if_type? && node.else?
          return false if !empty_if_branch?(node) && node.elsif?

          !empty_elsif_branch?(node)
        end

        def empty_if_branch?(node)
          return false unless (parent = node.parent)
          return true unless parent.if_type?
          return true unless (if_branch = parent.if_branch)

          if_branch.if_type? && !if_branch.body
        end

        def empty_elsif_branch?(node)
          return false unless (else_branch = node.else_branch)

          else_branch.if_type? && !else_branch.body
        end

        def else_branch?(node)
          node.else_branch && !node.else_branch.if_type?
        end

        # rubocop:disable Metrics/AbcSize
        def branch_range(node)
          if empty_if_branch?(node) && else_branch?(node)
            node.source_range.with(end_pos: node.loc.else.begin_pos)
          elsif node.loc.else
            node.source_range.with(end_pos: node.condition.source_range.end_pos)
          elsif all_branches_body_missing?(node)
            if_node = node.ancestors.detect(&:if?)
            node.source_range.join(if_node.loc.end.end)
          else
            node.source_range
          end
        end
        # rubocop:enable Metrics/AbcSize

        def all_branches_body_missing?(node)
          return false unless node.parent&.if_type?

          node.parent.branches.compact.empty?
        end

        def deletion_range(range)
          # Collect a range between the start of the `if` node and the next relevant node,
          # including final new line.
          # Based on `RangeHelp#range_by_whole_lines` but allows the `if` to not start
          # on the first column.
          buffer = @processed_source.buffer

          last_line = buffer.source_line(range.last_line)
          end_offset = last_line.length - range.last_column + 1

          range.adjust(end_pos: end_offset).intersect(buffer.source_range)
        end
      end
    end
  end
end
