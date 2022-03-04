module BadgeAchievements
  class BadgeAwardWorker
    include Sidekiq::Worker

    sidekiq_options queue: :high_priority, retry: 10

    def perform(usernames, badge_slug, message)
      if (award_class = "Badges::#{badge_slug.classify}".safe_constantize)
        award_class.call
      else
        Badges::Award.call(
          User.where(username: usernames),
          badge_slug,
          message,
        )
      end
    end
  end
end
