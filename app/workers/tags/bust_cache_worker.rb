module Tags
  class BustCacheWorker < BustCacheBaseWorker
    def perform(tag_name)
      tag = Tag.find_by(name: tag_name)
      return unless tag

      EdgeCache::BustTag.call(tag)
    end
  end
end
