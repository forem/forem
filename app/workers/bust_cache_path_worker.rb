class BustCachePathWorker < BustCacheBaseWorker
  def perform(path)
    EdgeCache::Bust.call(path)
  end
end
