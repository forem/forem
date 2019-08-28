module Notifications
  class NotifiableActionJob < ApplicationJob
    queue_as :send_notifiable_action_notification

    def perform(notifiable_id, notifiable_type, action, service = Notifications::NotifiableAction::Send)
      # checking type, but leaving space for notifyable types
      return unless notifiable_type == "Article"

      notifiable = notifiable_type.constantize.find_by(id: notifiable_id)
      service.call(notifiable, action) if notifiable
    end
  end
end
