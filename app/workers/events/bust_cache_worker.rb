module Events
  class BustCacheWorker < BustCacheBaseWorker
    sidekiq_options queue: :low_priority

    def perform
      EdgeCache::BustEvents.call
    end
  end
end
