class BustCachePathWorker < BustCacheBaseWorker
  def perform(path)
    CacheBuster.bust(path)
  end
end
