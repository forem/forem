module DataUpdateScripts
  class ClearBadgeAchievementNotificationCache
    def run
      Badge.ids.each do |badge_id|
        Rails.cache.delete("activity-badge-reward-#{badge_id}")
      end
    end
  end
end
