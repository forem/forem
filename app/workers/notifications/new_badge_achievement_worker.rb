module Notifications
  class NewBadgeAchievementWorker
    include Sidekiq::Worker
    sidekiq_options queue: :low_priority, retry: 10

    def perform(badge_achievement_id)
      badge_achievement = BadgeAchievement.find_by(id: badge_achievement_id)
      Notifications::NewBadgeAchievement::Send.call(badge_achievement) if badge_achievement
    end
  end
end
