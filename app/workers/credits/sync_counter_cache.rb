module Credits
  class SyncCounterCache
    include Sidekiq::Job

    sidekiq_options queue: :low_priority, retry: 10

    def perform
      Credit.counter_culture_fix_counts only: %i[user organization]
    end
  end
end
