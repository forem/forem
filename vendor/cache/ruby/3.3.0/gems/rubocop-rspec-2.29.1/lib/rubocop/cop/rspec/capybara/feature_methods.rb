# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      module Capybara
        # Checks for consistent method usage in feature specs.
        #
        # By default, the cop disables all Capybara-specific methods that have
        # the same native RSpec method (e.g. are just aliases). Some teams
        # however may prefer using some of the Capybara methods (like `feature`)
        # to make it obvious that the test uses Capybara, while still disable
        # the rest of the methods, like `given` (alias for `let`), `background`
        # (alias for `before`), etc. You can configure which of the methods to
        # be enabled by using the EnabledMethods configuration option.
        #
        # @example
        #   # bad
        #   feature 'User logs in' do
        #     given(:user) { User.new }
        #
        #     background do
        #       visit new_session_path
        #     end
        #
        #     scenario 'with OAuth' do
        #       # ...
        #     end
        #   end
        #
        #   # good
        #   describe 'User logs in' do
        #     let(:user) { User.new }
        #
        #     before do
        #       visit new_session_path
        #     end
        #
        #     it 'with OAuth' do
        #       # ...
        #     end
        #   end
        #
        class FeatureMethods < Base
          extend AutoCorrector
          include InsideExampleGroup

          MSG = 'Use `%<replacement>s` instead of `%<method>s`.'

          # https://github.com/teamcapybara/capybara/blob/e283c1aeaa72441f5403963577e16333bf111a81/lib/capybara/rspec/features.rb#L31-L36
          MAP = {
            background: :before,
            scenario:   :it,
            xscenario:  :xit,
            given:      :let,
            given!:     :let!,
            feature:    :describe
          }.freeze

          # @!method capybara_speak(node)
          def_node_matcher :capybara_speak, <<~PATTERN
            {#{MAP.keys.map(&:inspect).join(' ')}}
          PATTERN

          # @!method feature_method(node)
          def_node_matcher :feature_method, <<~PATTERN
            (block
              $(send #rspec? $#capybara_speak ...)
            ...)
          PATTERN

          def on_block(node) # rubocop:disable InternalAffairs/NumblockHandler
            return unless inside_example_group?(node)

            feature_method(node) do |send_node, match|
              next if enabled?(match)

              add_offense(send_node.loc.selector) do |corrector|
                corrector.replace(send_node.loc.selector, MAP[match].to_s)
              end
            end
          end

          def message(range)
            name = range.source.to_sym
            format(MSG, method: name, replacement: MAP[name])
          end

          private

          def enabled?(method_name)
            enabled_methods.include?(method_name)
          end

          def enabled_methods
            cop_config
              .fetch('EnabledMethods', [])
              .map(&:to_sym)
          end
        end
      end
    end
  end
end
