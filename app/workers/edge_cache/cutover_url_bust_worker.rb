module EdgeCache
  # Temporary worker paired with `EdgeCache::CutoverUrlBust` to execute targeted
  # Fastly URL purges asynchronously during the 50-hour PR #24746 deploy cutover.
  class CutoverUrlBustWorker < BustCacheBaseWorker
    sidekiq_options queue: :medium_priority, retry: 3, lock: :until_executing

    def perform(paths)
      EdgeCache::CutoverUrlBust.purge_now(paths)
    end
  end
end
