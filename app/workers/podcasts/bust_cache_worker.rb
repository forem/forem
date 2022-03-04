module Podcasts
  class BustCacheWorker < BustCacheBaseWorker
    def perform(path)
      EdgeCache::BustPodcast.call(path)
    end
  end
end
