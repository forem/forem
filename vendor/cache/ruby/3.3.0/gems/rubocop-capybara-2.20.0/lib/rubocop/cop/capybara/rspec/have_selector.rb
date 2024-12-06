# frozen_string_literal: true

module RuboCop
  module Cop
    module Capybara
      module RSpec
        # Use `have_css` or `have_xpath` instead of `have_selector`.
        #
        # @example
        #   # bad
        #   expect(foo).to have_selector(:css, 'bar')
        #
        #   # good
        #   expect(foo).to have_css('bar')
        #
        #   # bad
        #   expect(foo).to have_selector(:xpath, 'bar')
        #
        #   # good
        #   expect(foo).to have_xpath('bar')
        #
        # @example DefaultSelector: css (default)
        #   # bad
        #   expect(foo).to have_selector('bar')
        #
        #   # good
        #   expect(foo).to have_css('bar')
        #
        # @example DefaultSelector: xpath
        #   # bad
        #   expect(foo).to have_selector('bar')
        #
        #   # good
        #   expect(foo).to have_xpath('bar')
        #
        class HaveSelector < ::RuboCop::Cop::Base
          extend AutoCorrector
          include RangeHelp

          MSG = 'Use `%<good>s` instead of `have_selector`.'
          RESTRICT_ON_SEND = %i[have_selector].freeze
          SELECTORS = %i[css xpath].freeze

          def on_send(node)
            argument = node.first_argument
            on_select_with_type(node, argument) if argument.sym_type?
            on_select_without_type(node) if %i[str dstr].include?(argument.type)
          end

          private

          def on_select_with_type(node, type)
            return unless SELECTORS.include?(type.value)

            add_offense(node, message: message_typed(type)) do |corrector|
              corrector.remove(deletion_range(type, node.arguments[1]))
              corrector.replace(node.loc.selector, "have_#{type.value}")
            end
          end

          def message_typed(type)
            format(MSG, good: "have_#{type.value}")
          end

          def deletion_range(first_argument, second_argument)
            range_between(first_argument.source_range.begin_pos,
                          second_argument.source_range.begin_pos)
          end

          def on_select_without_type(node)
            add_offense(node, message: message_untyped) do |corrector|
              corrector.replace(node.loc.selector, "have_#{default_selector}")
            end
          end

          def message_untyped
            format(MSG, good: "have_#{default_selector}")
          end

          def default_selector
            cop_config.fetch('DefaultSelector', 'css')
          end
        end
      end
    end
  end
end
