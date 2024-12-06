# frozen_string_literal: true

require_relative 'actions_matcher'

module Pundit
  module Matchers
    module Utils
      module AllActions
        # Handles all the checks in `forbid_all_actions` matcher.
        class ForbiddenActionsMatcher < AllActions::ActionsMatcher
          private

          def actual_actions
            policy_info.forbidden_actions
          end
        end
      end
    end
  end
end
