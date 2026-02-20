module BadgeAchievements
  class SendEmailNotificationWorker
    include Sidekiq::Job
    include Sidekiq::Throttled::Job

    sidekiq_throttle(concurrency: { limit: 8 })

    sidekiq_options queue: :low_priority, retry: 10

    def perform(badge_achievement_id)
      badge_achievement = BadgeAchievement.find_by(id: badge_achievement_id)
      return unless badge_achievement

      NotifyMailer.with(badge_achievement: badge_achievement).new_badge_email.deliver_now
    end
  end
end
