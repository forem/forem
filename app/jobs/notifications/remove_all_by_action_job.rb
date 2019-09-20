module Notifications
  class RemoveAllByActionJob < ApplicationJob
    queue_as :remove_all_by_action_notifications

    def perform(notifiable_id, notifiable_type, action, service = Notifications::RemoveAllByAction)
      service.call(notifiable_id, notifiable_type, action)
    end
  end
end
