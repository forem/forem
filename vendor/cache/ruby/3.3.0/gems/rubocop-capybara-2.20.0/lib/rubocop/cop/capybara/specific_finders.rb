# frozen_string_literal: true

module RuboCop
  module Cop
    module Capybara
      # Checks if there is a more specific finder offered by Capybara.
      #
      # @example
      #   # bad
      #   find('#some-id')
      #   find('[id=some-id]')
      #   find(:css, '#some-id')
      #
      #   # good
      #   find_by_id('some-id')
      #
      class SpecificFinders < ::RuboCop::Cop::Base
        extend AutoCorrector
        include RangeHelp

        MSG = 'Prefer `find_by_id` over `find`.'
        RESTRICT_ON_SEND = %i[find].freeze

        # @!method find_argument(node)
        def_node_matcher :find_argument, <<~PATTERN
          (send _ :find $(sym :css)? (str $_) ...)
        PATTERN

        # @!method class_options(node)
        def_node_search :class_options, <<~PATTERN
          (pair (sym :class) $_ ...)
        PATTERN

        def on_send(node)
          find_argument(node) do |sym, arg|
            next if CssSelector.pseudo_classes(arg).any?
            next if CssSelector.multiple_selectors?(arg)

            on_attr(node, sym, arg) if attribute?(arg)
            on_id(node, sym, arg) if CssSelector.id?(arg)
          end
        end

        private

        def on_attr(node, sym, arg)
          attrs = CssSelector.attributes(arg)
          return unless (id = attrs['id'])
          return if attrs['class']

          register_offense(node, sym, replaced_arguments(arg, id))
        end

        def on_id(node, sym, arg)
          return if CssSelector.attributes(arg).any?

          id = CssSelector.id(arg)
          register_offense(node, sym, "'#{id}'",
                           CssSelector.classes(arg.sub("##{id}", '')))
        end

        def attribute?(arg)
          CssSelector.attribute?(arg) &&
            CapybaraHelp.common_attributes?(arg)
        end

        def register_offense(node, sym, id, classes = [])
          add_offense(offense_range(node)) do |corrector|
            corrector.replace(node.loc.selector, 'find_by_id')
            corrector.replace(node.first_argument, id.delete('\\'))
            unless classes.compact.empty?
              autocorrect_classes(corrector, node, classes)
            end
            corrector.remove(deletion_range(node)) unless sym.empty?
          end
        end

        def deletion_range(node)
          range_between(node.first_argument.source_range.end_pos,
                        node.arguments[1].source_range.end_pos)
        end

        def autocorrect_classes(corrector, node, classes)
          if (options = class_options(node).first)
            append_options(classes, options)
            corrector.replace(options, classes.to_s)
          else
            corrector.insert_after(node.first_argument,
                                   keyword_argument_class(classes))
          end
        end

        def append_options(classes, options)
          classes << options.value if options.str_type?
          options.each_value { |v| classes << v.value } if options.array_type?
        end

        def keyword_argument_class(classes)
          value = classes.size > 1 ? classes.to_s : "'#{classes.first}'"
          ", class: #{value}"
        end

        def replaced_arguments(arg, id)
          options = to_options(CssSelector.attributes(arg))
          options.empty? ? id : "#{id}, #{options}"
        end

        def to_options(attrs)
          attrs.each.map do |key, value|
            next if key == 'id'

            "#{key}: #{value}"
          end.compact.join(', ')
        end

        def offense_range(node)
          range_between(node.loc.selector.begin_pos, end_pos(node))
        end

        def end_pos(node)
          if node.loc.end
            node.loc.end.end_pos
          else
            node.source_range.end_pos
          end
        end
      end
    end
  end
end
