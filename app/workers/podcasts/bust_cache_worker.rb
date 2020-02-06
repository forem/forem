module Podcasts
  class BustCacheWorker
    include Sidekiq::Worker

    sidekiq_options queue: :high_priority, retry: 10

    def perform(path)
      CacheBuster.bust_podcast(path)
    end
  end
end
