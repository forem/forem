module Notifications
  class NewBadgeAchievementJob < ApplicationJob
    queue_as :send_new_badge_achievement_notification

    def perform(badge_achievement_id, service = NewBadgeAchievement::Send)
      badge_achievement = BadgeAchievement.find_by(id: badge_achievement_id)
      return unless badge_achievement

      service.call(badge_achievement)
    end
  end
end
