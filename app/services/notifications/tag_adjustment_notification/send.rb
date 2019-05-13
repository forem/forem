# send notifications about a tag adjustment
module Notifications
  module TagAdjustmentNotification
    class Send
      def initialize(tag_adjustment)
        @tag_adjustment = tag_adjustment
      end

      def self.call(*args)
        new(*args).call
      end

      def call
        article = tag_adjustment.article
        json_data = {
          article: { title: article.title, path: article.path },
          adjustment_type: tag_adjustment.adjustment_type,
          status: tag_adjustment.status,
          reason_for_adjustment: tag_adjustment.reason_for_adjustment,
          tag_name: tag_adjustment.tag_name
        }
        notification = Notification.create(
          user_id: article.user_id,
          notifiable_id: tag_adjustment.id,
          notifiable_type: tag_adjustment.class.name,
          json_data: json_data,
        )
        article.user.update_column(:last_moderation_notification, Time.current)
        notification
      end

      private

      attr_reader :tag_adjustment
    end
  end
end
