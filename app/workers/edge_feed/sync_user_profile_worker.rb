module EdgeFeed
  # Mirrors a single user's compact feed personalization profile (`user:<user_id>`)
  # to Fastly KV Store. Triggered lazily when `UserActivity` updates or when Fastly
  # Compute falls back to origin with `X-Forem-Edge-Miss: user-profile`.
  class SyncUserProfileWorker
    include Sidekiq::Job

    sidekiq_options queue: :low_priority, retry: 3, lock: :until_executing, on_conflict: :replace

    def perform(user_id)
      return unless FeatureFlag.enabled?(:fastly_edge_feed_mirror)
      return unless EdgeFeed::KvClient.configured?

      user = User.includes(:user_activity, :setting).find_by(id: user_id)
      return unless user

      profile = EdgeFeed::UserProfileBuilder.new(user: user).build
      EdgeFeed::KvClient.new.put("user:#{user.id}", profile)
    end
  end
end
