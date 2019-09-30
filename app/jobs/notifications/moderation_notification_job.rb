module Notifications
  class ModerationNotificationJob < ApplicationJob
    queue_as :send_moderation_notification

    def perform(notifiable_id, service = Notifications::Moderation::Send)
      random_moderators = Notifications::Moderation.available_moderators.order(Arel.sql("RANDOM()")).first(2)
      return unless random_moderators.any?

      # notifiable is currently only comment
      notifiable = Comment.find_by(id: notifiable_id)
      return unless notifiable

      random_moderators.each do |mod|
        service.call(mod, notifiable)
      end
    end
  end
end
