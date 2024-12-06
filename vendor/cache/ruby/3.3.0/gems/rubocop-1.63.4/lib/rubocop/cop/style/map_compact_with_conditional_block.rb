# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Prefer `select` or `reject` over `map { ... }.compact`.
      #
      # @example
      #
      #   # bad
      #   array.map { |e| some_condition? ? e : next }.compact
      #
      #   # bad
      #   array.map do |e|
      #     if some_condition?
      #       e
      #     else
      #       next
      #     end
      #   end.compact
      #
      #   # bad
      #   array.map do |e|
      #     next if some_condition?
      #
      #     e
      #   end.compact
      #
      #   # bad
      #   array.map do |e|
      #     e if some_condition?
      #   end.compact
      #
      #   # good
      #   array.select { |e| some_condition? }
      #
      #   # good
      #   array.reject { |e| some_condition? }
      #
      class MapCompactWithConditionalBlock < Base
        extend AutoCorrector

        MSG = 'Replace `map { ... }.compact` with `%<method>s`.'

        # @!method map_and_compact?(node)
        def_node_matcher :map_and_compact?, <<~RUBY
          (call
            (block
              (call _ :map)
              (args
                $(arg _))
              {
                (if $_ $(lvar _) {next nil?})
                (if $_ {next nil?} $(lvar _))
                (if $_ (next $(lvar _)) {next nil nil?})
                (if $_ {next nil nil?} (next $(lvar _)))
                (begin
                  {
                    (if $_ next nil?)
                    (if $_ nil? next)
                  }
                  $(lvar _))
                (begin
                  {
                    (if $_ (next $(lvar _)) nil?)
                    (if $_ nil? (next $(lvar _)))
                  }
                  (nil))
              }) :compact)
        RUBY

        def on_send(node)
          map_and_compact?(node) do |block_argument_node, condition_node, return_value_node|
            return unless returns_block_argument?(block_argument_node, return_value_node)
            return if condition_node.parent.elsif?

            method = truthy_branch?(return_value_node) ? 'select' : 'reject'
            range = range(node)

            add_offense(range, message: format(MSG, method: method)) do |corrector|
              corrector.replace(
                range,
                "#{method} { |#{block_argument_node.source}| #{condition_node.source} }"
              )
            end
          end
        end
        alias on_csend on_send

        private

        def returns_block_argument?(block_argument_node, return_value_node)
          block_argument_node.name == return_value_node.children.first
        end

        def truthy_branch?(node)
          if node.parent.begin_type?
            truthy_branch_for_guard?(node)
          elsif node.parent.next_type?
            truthy_branch_for_if?(node.parent)
          else
            truthy_branch_for_if?(node)
          end
        end

        def truthy_branch_for_if?(node)
          if_node = node.parent

          if if_node.if? || if_node.ternary?
            if_node.if_branch == node
          elsif if_node.unless?
            if_node.else_branch == node
          end
        end

        def truthy_branch_for_guard?(node)
          if_node = node.left_sibling

          if if_node.if?
            if_node.if_branch.arguments.any?
          else
            if_node.if_branch.arguments.none?
          end
        end

        def range(node)
          map_node = node.receiver.send_node

          map_node.loc.selector.join(node.source_range.end)
        end
      end
    end
  end
end
