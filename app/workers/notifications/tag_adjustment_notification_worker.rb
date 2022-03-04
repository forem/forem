module Notifications
  class TagAdjustmentNotificationWorker
    include Sidekiq::Worker

    sidekiq_options queue: :medium_priority, retry: 10

    def perform(tag_adjustment_id)
      tag_adjustment = TagAdjustment.find_by(id: tag_adjustment_id)
      return unless tag_adjustment

      Notifications::TagAdjustmentNotification::Send.call(tag_adjustment)
    end
  end
end
