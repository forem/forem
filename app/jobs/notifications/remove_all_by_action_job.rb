module Notifications
  class RemoveAllByActionJob < ApplicationJob
    queue_as :remove_all_by_action_notifications

    def perform(notifiable, action, service = Notifications::RemoveAllByAction)
      service.call(notifiable, action)
    end
  end
end
