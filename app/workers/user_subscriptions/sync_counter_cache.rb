module UserSubscriptions
  class SyncCounterCache
    include Sidekiq::Worker

    sidekiq_options queue: :default, retry: 10

    def perform
      UserSubscription.counter_culture_fix_counts only: %i[subscriber user_subscription_sourceable]
    end
  end
end
