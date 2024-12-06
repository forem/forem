# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Access modifiers should be declared to apply to a group of methods
      # or inline before each method, depending on configuration.
      # EnforcedStyle config covers only method definitions.
      # Applications of visibility methods to symbols can be controlled
      # using AllowModifiersOnSymbols config.
      #
      # @safety
      #   Autocorrection is not safe, because the visibility of dynamically
      #   defined methods can vary depending on the state determined by
      #   the group access modifier.
      #
      # @example EnforcedStyle: group (default)
      #   # bad
      #   class Foo
      #
      #     private def bar; end
      #     private def baz; end
      #
      #   end
      #
      #   # good
      #   class Foo
      #
      #     private
      #
      #     def bar; end
      #     def baz; end
      #
      #   end
      #
      # @example EnforcedStyle: inline
      #   # bad
      #   class Foo
      #
      #     private
      #
      #     def bar; end
      #     def baz; end
      #
      #   end
      #
      #   # good
      #   class Foo
      #
      #     private def bar; end
      #     private def baz; end
      #
      #   end
      #
      # @example AllowModifiersOnSymbols: true (default)
      #   # good
      #   class Foo
      #
      #     private :bar, :baz
      #
      #   end
      #
      # @example AllowModifiersOnSymbols: false
      #   # bad
      #   class Foo
      #
      #     private :bar, :baz
      #
      #   end
      class AccessModifierDeclarations < Base
        extend AutoCorrector

        include ConfigurableEnforcedStyle
        include RangeHelp

        GROUP_STYLE_MESSAGE = [
          '`%<access_modifier>s` should not be',
          'inlined in method definitions.'
        ].join(' ')

        INLINE_STYLE_MESSAGE = [
          '`%<access_modifier>s` should be',
          'inlined in method definitions.'
        ].join(' ')

        RESTRICT_ON_SEND = %i[private protected public module_function].freeze

        ALLOWED_NODE_TYPES = %i[pair block].freeze

        # @!method access_modifier_with_symbol?(node)
        def_node_matcher :access_modifier_with_symbol?, <<~PATTERN
          (send nil? {:private :protected :public :module_function} (sym _))
        PATTERN

        def on_send(node)
          return unless node.access_modifier?
          return if ALLOWED_NODE_TYPES.include?(node.parent&.type)
          return if allow_modifiers_on_symbols?(node)

          if offense?(node)
            add_offense(node.loc.selector) do |corrector|
              autocorrect(corrector, node)
            end
            opposite_style_detected
          else
            correct_style_detected
          end
        end

        private

        def autocorrect(corrector, node)
          case style
          when :group
            def_node = find_corresponding_def_node(node)
            return unless def_node

            replace_def(corrector, node, def_node)
          when :inline
            remove_node(corrector, node)
            select_grouped_def_nodes(node).each do |grouped_def_node|
              insert_inline_modifier(corrector, grouped_def_node, node.method_name)
            end
          end
        end

        def allow_modifiers_on_symbols?(node)
          cop_config['AllowModifiersOnSymbols'] && access_modifier_with_symbol?(node)
        end

        def offense?(node)
          (group_style? && access_modifier_is_inlined?(node) &&
            !right_siblings_same_inline_method?(node)) ||
            (inline_style? && access_modifier_is_not_inlined?(node))
        end

        def group_style?
          style == :group
        end

        def inline_style?
          style == :inline
        end

        def access_modifier_is_inlined?(node)
          node.arguments.any?
        end

        def access_modifier_is_not_inlined?(node)
          !access_modifier_is_inlined?(node)
        end

        def right_siblings_same_inline_method?(node)
          node.right_siblings.any? do |sibling|
            sibling.send_type? && sibling.method?(node.method_name) && !sibling.arguments.empty?
          end
        end

        def message(range)
          access_modifier = range.source

          if group_style?
            format(GROUP_STYLE_MESSAGE, access_modifier: access_modifier)
          elsif inline_style?
            format(INLINE_STYLE_MESSAGE, access_modifier: access_modifier)
          end
        end

        def find_corresponding_def_node(node)
          if access_modifier_with_symbol?(node)
            method_name = node.first_argument.value
            node.parent.each_child_node(:def).find do |child|
              child.method?(method_name)
            end
          else
            node.first_argument
          end
        end

        def find_argument_less_modifier_node(node)
          return unless (parent = node.parent)

          parent.each_child_node(:send).find do |child|
            child.method?(node.method_name) && child.arguments.empty?
          end
        end

        def select_grouped_def_nodes(node)
          node.right_siblings.take_while do |sibling|
            !(sibling.send_type? && sibling.bare_access_modifier_declaration?)
          end.select(&:def_type?)
        end

        def replace_def(corrector, node, def_node)
          source = def_source(node, def_node)
          argument_less_modifier_node = find_argument_less_modifier_node(node)
          if argument_less_modifier_node
            corrector.insert_after(argument_less_modifier_node, "\n\n#{source}")
          elsif (ancestor = node.each_ancestor(:block, :class, :module).first)

            corrector.insert_before(ancestor.loc.end, "#{node.method_name}\n\n#{source}\n")
          else
            corrector.replace(node, "#{node.method_name}\n\n#{source}")
            return
          end

          remove_node(corrector, def_node)
          remove_node(corrector, node)
        end

        def insert_inline_modifier(corrector, node, modifier_name)
          corrector.insert_before(node, "#{modifier_name} ")
        end

        def remove_node(corrector, node)
          corrector.remove(range_with_comments_and_lines(node))
        end

        def def_source(node, def_node)
          [*processed_source.ast_with_comments[node].map(&:text), def_node.source].join("\n")
        end
      end
    end
  end
end
