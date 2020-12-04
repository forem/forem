module UserSubscriptions
  class SyncCounterCache
    include Sidekiq::Worker

    sidekiq_options queue: :default, retry: 10

    def perform
      UserSubscription.counter_culture_fix_counts
    end
  end
end
