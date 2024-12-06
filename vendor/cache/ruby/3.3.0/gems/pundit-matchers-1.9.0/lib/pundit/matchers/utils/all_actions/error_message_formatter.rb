# frozen_string_literal: true

module Pundit
  module Matchers
    module Utils
      module AllActions
        # Adds #message method which generates failed assertion message
        # for *_all_actions matchers.
        #
        # Expects methods to be defined:
        # * matcher - instance which has `AllActions::ActionsMatcher` as a parent class
        # * expected_kind - string with expected actions type (can be "forbidden" or "permitted")
        # * opposite_kind - string with oposite then expected actions type (can be "permitted" or "forbidden")
        module ErrorMessageFormatter
          def message
            "#{policy_name} expected to have all actions #{expected_kind}, " \
            "but #{mismatches_are(missed_expected_actions)} #{opposite_kind}"
          end

          private

          attr_reader :matcher, :expected_kind, :opposite_kind

          def policy
            matcher.policy
          end

          def missed_expected_actions
            matcher.missed_expected_actions
          end

          def policy_name
            policy.class.name
          end

          def mismatches_are(mismatches)
            if mismatches.count == 1
              "#{mismatches} is"
            else
              "#{mismatches} are"
            end
          end
        end
      end
    end
  end
end
