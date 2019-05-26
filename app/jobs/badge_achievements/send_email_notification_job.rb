module BadgeAchievements
  class SendEmailNotificationJob < ApplicationJob
    queue_as :badge_achievements_send_email_notification

    def perform(badge_achievement_id)
      badge_achievement = BadgeAchievement.find_by(id: badge_achievement_id)
      NotifyMailer.new_badge_email(badge_achievement).deliver_now if badge_achievement
    end
  end
end
