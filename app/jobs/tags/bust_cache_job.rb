module Tags
  class BustCacheJob < ApplicationJob
    queue_as :tags_bust_cache

    def perform(tag_name)
      tag = Tag.find_by(name: tag_name)
      return unless tag

      CacheBuster.bust_tag(tag)
    end
  end
end
