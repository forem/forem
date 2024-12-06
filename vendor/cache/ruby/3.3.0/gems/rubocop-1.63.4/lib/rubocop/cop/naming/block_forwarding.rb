# frozen_string_literal: true

module RuboCop
  module Cop
    module Naming
      # In Ruby 3.1, anonymous block forwarding has been added.
      #
      # This cop identifies places where `do_something(&block)` can be replaced
      # by `do_something(&)`.
      #
      # It also supports the opposite style by alternative `explicit` option.
      # You can specify the block variable name for autocorrection with `BlockForwardingName`.
      # The default variable name is `block`. If the name is already in use, it will not be
      # autocorrected.
      #
      # @example EnforcedStyle: anonymous (default)
      #
      #   # bad
      #   def foo(&block)
      #     bar(&block)
      #   end
      #
      #   # good
      #   def foo(&)
      #     bar(&)
      #   end
      #
      # @example EnforcedStyle: explicit
      #
      #   # bad
      #   def foo(&)
      #     bar(&)
      #   end
      #
      #   # good
      #   def foo(&block)
      #     bar(&block)
      #   end
      #
      class BlockForwarding < Base
        include ConfigurableEnforcedStyle
        include RangeHelp
        extend AutoCorrector
        extend TargetRubyVersion

        minimum_target_ruby_version 3.1

        MSG = 'Use %<style>s block forwarding.'

        def self.autocorrect_incompatible_with
          [Lint::AmbiguousOperator, Style::ArgumentsForwarding]
        end

        def on_def(node)
          return if node.arguments.empty?

          last_argument = node.last_argument
          return if expected_block_forwarding_style?(node, last_argument)

          forwarded_args = node.each_descendant(:block_pass).with_object([]) do |block_pass, result|
            return nil if invalidates_syntax?(block_pass)
            next unless block_argument_name_matched?(block_pass, last_argument)

            result << block_pass
          end

          forwarded_args.each do |forwarded_arg|
            register_offense(forwarded_arg, node)
          end

          register_offense(last_argument, node)
        end
        alias on_defs on_def

        private

        def expected_block_forwarding_style?(node, last_argument)
          if style == :anonymous
            !explicit_block_argument?(last_argument) ||
              use_kwarg_in_method_definition?(node) ||
              use_block_argument_as_local_variable?(node, last_argument.source[1..])
          else
            !anonymous_block_argument?(last_argument)
          end
        end

        def block_argument_name_matched?(block_pass_node, last_argument)
          return false if block_pass_node.children.first&.sym_type?

          last_argument.source == block_pass_node.source
        end

        # Prevents the following syntax error:
        #
        # # foo.rb
        # def foo(&)
        #   block_method do
        #     bar(&)
        #   end
        # end
        #
        # $ ruby -vc foo.rb
        # ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [x86_64-darwin22]
        # foo.rb: foo.rb:4: anonymous block parameter is also used within block (SyntaxError)
        #
        def invalidates_syntax?(block_pass_node)
          block_pass_node.each_ancestor(:block, :numblock).any?
        end

        def use_kwarg_in_method_definition?(node)
          node.arguments.each_descendant(:kwarg, :kwoptarg).any?
        end

        def anonymous_block_argument?(node)
          node.blockarg_type? && node.name.nil?
        end

        def explicit_block_argument?(node)
          node.blockarg_type? && !node.name.nil?
        end

        def register_offense(block_argument, node)
          add_offense(block_argument, message: format(MSG, style: style)) do |corrector|
            if style == :anonymous
              corrector.replace(block_argument, '&')

              arguments = block_argument.parent

              add_parentheses(arguments, corrector) unless arguments.parenthesized_call?
            else
              unless use_block_argument_as_local_variable?(node, block_forwarding_name)
                corrector.replace(block_argument, "&#{block_forwarding_name}")
              end
            end
          end
        end

        def use_block_argument_as_local_variable?(node, last_argument)
          return false if node.body.nil?

          node.body.each_descendant(:lvar, :lvasgn).any? do |lvar|
            !lvar.parent.block_pass_type? && lvar.node_parts[0].to_s == last_argument
          end
        end

        def block_forwarding_name
          cop_config.fetch('BlockForwardingName', 'block')
        end
      end
    end
  end
end
