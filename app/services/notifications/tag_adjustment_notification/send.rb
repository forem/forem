# send notifications about a tag adjustment
module Notifications
  module TagAdjustmentNotification
    class Send
      def self.call(...)
        new(...).call
      end

      def initialize(tag_adjustment)
        @tag_adjustment = tag_adjustment
      end

      delegate :user_data, to: Notifications

      def call
        article = tag_adjustment.article
        json_data = {
          user: user_data(User.mascot_account),
          article: { title: article.title, path: article.path },
          adjustment_type: tag_adjustment.adjustment_type,
          status: tag_adjustment.status,
          reason_for_adjustment: tag_adjustment.reason_for_adjustment,
          tag_name: tag_adjustment.tag_name
        }
        Notification.create(
          user_id: article.user_id,
          notifiable_id: tag_adjustment.id,
          notifiable_type: tag_adjustment.class.name,
          json_data: json_data,
        )
      end

      private

      attr_reader :tag_adjustment
    end
  end
end
