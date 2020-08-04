module BadgeAchievements
  class BadgeAwardWorker
    include Sidekiq::Worker

    sidekiq_options queue: :high_priority, retry: 10

    def perform(usernames, badge_slug, message)
      BadgeRewarder.award_badges(usernames, badge_slug, message)
    end
  end
end
