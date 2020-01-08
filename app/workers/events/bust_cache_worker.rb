module Events
  class BustCacheWorker
    include Sidekiq::Worker
    sidekiq_options queue: :low_priority, retry: 10

    def perform
      CacheBuster.bust_events
    end
  end
end
