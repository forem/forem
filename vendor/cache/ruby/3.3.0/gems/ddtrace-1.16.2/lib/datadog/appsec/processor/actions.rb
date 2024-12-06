# frozen_string_literal: true

module Datadog
  module AppSec
    class Processor
      # Actions store the actions information in memory
      # Also, takes care of merging when RC send new information
      module Actions
        class << self
          def actions
            @actions ||= []
          end

          def fecth_configuration(action)
            actions.find { |action_configuration| action_configuration['id'] == action }
          end

          def merge(actions_to_merge)
            return if actions_to_merge.empty?

            if actions.empty?
              @actions = actions_to_merge
            else
              merged_actions = []
              actions_dup = actions.dup

              actions_to_merge.each do |new_action|
                existing_action = actions_dup.find { |action| new_action['id'] == action['id'] }

                # the old action is discard and the new kept
                actions_dup.delete(existing_action) if existing_action
                merged_actions << new_action
              end

              @actions = merged_actions.concat(actions_dup)
            end
          end

          private

          # Used in tests
          def reset
            @actions = []
          end
        end
      end
    end
  end
end
