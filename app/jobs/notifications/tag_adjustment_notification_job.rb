module Notifications
  class TagAdjustmentNotificationJob < ApplicationJob
    queue_as :send_tag_adjustment_notification

    def perform(tag_adjustment_id, service = Notifications::TagAdjustmentNotification::Send)
      tag_adjustment = TagAdjustment.find_by(id: tag_adjustment_id)
      return unless tag_adjustment

      service.call(tag_adjustment)
    end
  end
end
