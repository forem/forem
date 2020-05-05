module Tags
  class BustCacheWorker < BustCacheBaseWorker
    def perform(tag_name)
      tag = Tag.find_by(name: tag_name)
      return unless tag

      CacheBuster.bust_tag(tag)
    end
  end
end
