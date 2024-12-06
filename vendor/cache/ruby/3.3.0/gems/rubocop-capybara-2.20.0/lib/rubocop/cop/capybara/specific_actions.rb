# frozen_string_literal: true

module RuboCop
  module Cop
    module Capybara
      # Checks for there is a more specific actions offered by Capybara.
      #
      # @example
      #
      #   # bad
      #   find('a').click
      #   find('button.cls').click
      #   find('a', exact_text: 'foo').click
      #   find('div button').click
      #
      #   # good
      #   click_link
      #   click_button(class: 'cls')
      #   click_link(exact_text: 'foo')
      #   find('div').click_button
      #
      class SpecificActions < ::RuboCop::Cop::Base
        MSG = "Prefer `%<good_action>s` over `find('%<selector>s').click`."
        RESTRICT_ON_SEND = %i[click].freeze
        SPECIFIC_ACTION = {
          'button' => 'button',
          'a' => 'link'
        }.freeze

        # @!method click_on_selector(node)
        def_node_matcher :click_on_selector, <<-PATTERN
          (send _ :find (str $_) ...)
        PATTERN

        def on_send(node)
          click_on_selector(node.receiver) do |arg|
            next unless supported_selector?(arg)
            # Always check the last selector in the case of multiple selectors
            # separated by whitespace.
            # because the `.click` is executed on the element to
            # which the last selector points.
            next unless (selector = last_selector(arg))
            next unless (action = specific_action(selector))
            next unless replaceable?(node, arg, action)

            range = offense_range(node, node.receiver)
            add_offense(range, message: message(action, selector))
          end
        end

        private

        def specific_action(selector)
          SPECIFIC_ACTION[last_selector(selector)]
        end

        def replaceable?(node, arg, action)
          replaceable_attributes?(arg) &&
            CapybaraHelp.replaceable_option?(node.receiver, arg, action) &&
            CapybaraHelp.replaceable_pseudo_classes?(arg)
        end

        def replaceable_attributes?(selector)
          CapybaraHelp.replaceable_attributes?(
            CssSelector.attributes(selector)
          )
        end

        def supported_selector?(selector)
          !selector.match?(/[>,+~]/)
        end

        def last_selector(arg)
          arg.split.last[/^\w+/, 0]
        end

        def offense_range(node, receiver)
          receiver.loc.selector.with(end_pos: node.source_range.end_pos)
        end

        def message(action, selector)
          format(MSG,
                 good_action: good_action(action),
                 selector: selector)
        end

        def good_action(action)
          "click_#{action}"
        end
      end
    end
  end
end
