# frozen_string_literal: true

require_relative 'actions_matcher'

module Pundit
  module Matchers
    module Utils
      module AllActions
        # Handles all the checks in `permit_all_actions` matcher.
        class PermittedActionsMatcher < AllActions::ActionsMatcher
          private

          def actual_actions
            policy_info.permitted_actions
          end
        end
      end
    end
  end
end
