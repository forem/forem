module BadgeAchievements
  class BadgeAwardWorker
    include Sidekiq::Worker

    sidekiq_options queue: :high_priority, retry: 10

    def perform(usernames, badge_slug, message)
      if BadgeRewarder.respond_to?(badge_slug)
        BadgeRewarder.public_send(badge_slug)
      else
        BadgeRewarder.award_badges(usernames, badge_slug, message)
      end
    end
  end
end
