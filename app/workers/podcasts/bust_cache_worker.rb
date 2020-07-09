module Podcasts
  class BustCacheWorker < BustCacheBaseWorker
    def perform(path)
      CacheBuster.bust_podcast(path)
    end
  end
end
