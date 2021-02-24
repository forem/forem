class BustCachePathWorker < BustCacheBaseWorker
  def perform(path)
    EdgeCache::Buster.new.bust(path)
  end
end
