module Notifications
  class RemoveAllByActionJob < ApplicationJob
    queue_as :remove_all_by_action_notifications

    def perform(notifiable_ids, notifiable_type, action, service = Notifications::RemoveAllByAction)
      return unless %w[Article Comment Mention].include?(notifiable_type) && notifiable_ids.present?

      service.call(Array.wrap(notifiable_ids), notifiable_type, action)
    end
  end
end
