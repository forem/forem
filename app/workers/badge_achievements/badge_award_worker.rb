module BadgeAchievements
  class BadgeAwardWorker
    include Sidekiq::Job

    sidekiq_options queue: :high_priority, retry: 10

    def perform(usernames, badge_slug, message, include_default_description = true) # rubocop:disable Style/OptionalBooleanParameter
      if (award_class = "Badges::#{badge_slug.classify}".safe_constantize)
        award_class.call
      else
        Badges::Award.call(
          User.where(username: usernames),
          badge_slug,
          message,
          include_default_description: include_default_description,
        )
      end
    end
  end
end
