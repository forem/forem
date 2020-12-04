module UserSubscriptions
  class UpdateCounterCache
    include Sidekiq::Worker

    sidekiq_options queue: :default, retry: 10

    def perform
      UserSubscription.counter_culture_fix_counts column_name: "subscribed_to_user_subscriptions_count"
      UserSubscription.counter_culture_fix_counts column_name: "user_subscriptions_count"
    end
  end
end
