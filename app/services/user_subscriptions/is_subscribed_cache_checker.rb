module UserSubscriptions
  # This checks if the provided user is subscribed to the provided source
  # (returns boolean).
  class IsSubscribedCacheChecker
    attr_accessor :user, :source_type, :source_id

    def self.call(...)
      new(...).call
    end

    def initialize(user, params)
      @user = user
      @source_type = params[:source_type]
      @source_id = params[:source_id]
    end

    def call
      cache_key = "user-#{user.id}-#{user.updated_at.rfc3339}-#{user.subscribed_to_user_subscriptions_count}/" \
        "is_subscribed_#{source_type}_#{source_id}"
      Rails.cache.fetch(cache_key, expires_in: 24.hours) do
        UserSubscription.where(
          subscriber_id: user.id,
          user_subscription_sourceable_type: source_type,
          user_subscription_sourceable_id: source_id,
        ).any?
      end
    end
  end
end
