# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks that there are no repeated bodies
      # within `if/unless`, `case-when`, `case-in` and `rescue` constructs.
      #
      # With `IgnoreLiteralBranches: true`, branches are not registered
      # as offenses if they return a basic literal value (string, symbol,
      # integer, float, rational, complex, `true`, `false`, or `nil`), or
      # return an array, hash, regexp or range that only contains one of
      # the above basic literal values.
      #
      # With `IgnoreConstantBranches: true`, branches are not registered
      # as offenses if they return a constant value.
      #
      # @example
      #   # bad
      #   if foo
      #     do_foo
      #     do_something_else
      #   elsif bar
      #     do_foo
      #     do_something_else
      #   end
      #
      #   # good
      #   if foo || bar
      #     do_foo
      #     do_something_else
      #   end
      #
      #   # bad
      #   case x
      #   when foo
      #     do_foo
      #   when bar
      #     do_foo
      #   else
      #     do_something_else
      #   end
      #
      #   # good
      #   case x
      #   when foo, bar
      #     do_foo
      #   else
      #     do_something_else
      #   end
      #
      #   # bad
      #   begin
      #     do_something
      #   rescue FooError
      #     handle_error
      #   rescue BarError
      #     handle_error
      #   end
      #
      #   # good
      #   begin
      #     do_something
      #   rescue FooError, BarError
      #     handle_error
      #   end
      #
      # @example IgnoreLiteralBranches: true
      #   # good
      #   case size
      #   when "small" then 100
      #   when "medium" then 250
      #   when "large" then 1000
      #   else 250
      #   end
      #
      # @example IgnoreConstantBranches: true
      #   # good
      #   case size
      #   when "small" then SMALL_SIZE
      #   when "medium" then MEDIUM_SIZE
      #   when "large" then LARGE_SIZE
      #   else MEDIUM_SIZE
      #   end
      #
      class DuplicateBranch < Base
        MSG = 'Duplicate branch body detected.'

        def on_branching_statement(node)
          branches(node).each_with_object(Set.new) do |branch, previous|
            next unless consider_branch?(branch)

            add_offense(offense_range(branch)) unless previous.add?(branch)
          end
        end
        alias on_if on_branching_statement
        alias on_case on_branching_statement
        alias on_case_match on_branching_statement
        alias on_rescue on_branching_statement

        private

        def offense_range(duplicate_branch)
          parent = duplicate_branch.parent

          if parent.respond_to?(:else_branch) && parent.else_branch.equal?(duplicate_branch)
            if parent.if_type? && parent.ternary?
              duplicate_branch.source_range
            else
              parent.loc.else
            end
          else
            parent.source_range
          end
        end

        def branches(node)
          node.branches.compact
        end

        def consider_branch?(branch)
          return false if ignore_literal_branches? && literal_branch?(branch)
          return false if ignore_constant_branches? && const_branch?(branch)

          true
        end

        def ignore_literal_branches?
          cop_config.fetch('IgnoreLiteralBranches', false)
        end

        def ignore_constant_branches?
          cop_config.fetch('IgnoreConstantBranches', false)
        end

        def literal_branch?(branch) # rubocop:disable Metrics/CyclomaticComplexity
          return false if !branch.literal? || branch.xstr_type?
          return true if branch.basic_literal?

          branch.each_descendant.all? do |node|
            node.basic_literal? ||
              node.pair_type? || # hash keys and values are contained within a `pair` node
              (node.const_type? && ignore_constant_branches?)
          end
        end

        def const_branch?(branch)
          branch.const_type?
        end
      end
    end
  end
end
