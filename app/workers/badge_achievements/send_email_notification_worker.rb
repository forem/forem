module BadgeAchievements
  class SendEmailNotificationWorker
    include Sidekiq::Worker

    sidekiq_options queue: :low_priority, retry: 10

    def perform(badge_achievement_id)
      badge_achievement = BadgeAchievement.find_by(id: badge_achievement_id)
      NotifyMailer.new_badge_email(badge_achievement).deliver_now if badge_achievement
    end
  end
end
