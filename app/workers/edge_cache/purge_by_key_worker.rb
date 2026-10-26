module EdgeCache
  # Purges already-computed surrogate keys (or their fallback paths) outside the
  # request/job that computed them. Useful when the records behind the keys are
  # being deleted, so they can't be looked up again by a later job.
  class PurgeByKeyWorker < BustCacheBaseWorker
    def perform(keys, fallback_paths = nil)
      EdgeCache::PurgeByKey.call(keys, fallback_paths: fallback_paths)
    end
  end
end
