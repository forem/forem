module Events
  class BustCacheWorker < BustCacheBaseWorker
    sidekiq_options queue: :low_priority

    def perform
      CacheBuster.bust_events
    end
  end
end
