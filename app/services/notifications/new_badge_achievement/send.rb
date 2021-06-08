# send notifications about the new badge achievement
module Notifications
  module NewBadgeAchievement
    class Send
      def initialize(badge_achievement)
        @badge_achievement = badge_achievement
      end

      delegate :user_data, to: Notifications

      def self.call(...)
        new(...).call
      end

      def call
        Notification.create(
          user_id: badge_achievement.user.id,
          notifiable_id: badge_achievement.id,
          notifiable_type: "BadgeAchievement",
          action: nil,
          json_data: json_data,
        )
      end

      private

      attr_reader :badge_achievement

      def json_data
        {
          user: user_data(badge_achievement.user),
          badge_achievement: {
            badge_id: badge_achievement.badge_id,
            rewarding_context_message: badge_achievement.rewarding_context_message,
            badge: {
              title: badge_achievement.badge.title,
              description: badge_achievement.badge.description,
              badge_image_url: badge_achievement.badge.badge_image_url,
              credits_awarded: badge_achievement.badge.credits_awarded
            }
          }
        }
      end
    end
  end
end
