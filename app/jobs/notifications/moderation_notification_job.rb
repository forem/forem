module Notifications
  class ModerationNotificationJob < ApplicationJob
    queue_as :send_moderation_notification

    def perform(notifiable_id, service = Notifications::Moderation::Send)
      random_moderator = Notifications::Moderation.available_moderators.order(Arel.sql("RANDOM()")).first
      return unless random_moderator

      # notifiable is currently only comment
      notifiable = Comment.find_by(id: notifiable_id)
      return unless notifiable

      service.call(random_moderator, notifiable)
    end
  end
end
