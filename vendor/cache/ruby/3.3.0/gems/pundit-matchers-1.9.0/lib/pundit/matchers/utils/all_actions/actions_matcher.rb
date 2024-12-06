# frozen_string_literal: true

module Pundit
  module Matchers
    module Utils
      module AllActions
        # Parent class for specific all_action matcher. Should not be used directly.
        #
        # Expects methods in child class:
        # * actual_actions - list of actions which actually matches expected type.
        class ActionsMatcher
          attr_reader :policy_info

          def initialize(policy)
            @policy_info = PolicyInfo.new(policy)
          end

          def match?
            missed_expected_actions.empty?
          end

          def missed_expected_actions
            @missed_expected_actions ||= expected_actions - actual_actions
          end

          def policy
            policy_info.policy
          end

          private

          def expected_actions
            policy_info.actions
          end
        end
      end
    end
  end
end
