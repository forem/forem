module Tags
  class BustCacheWorker
    include Sidekiq::Worker

    sidekiq_options queue: :high_priority, retry: 10

    def perform(tag_name)
      tag = Tag.find_by(name: tag_name)
      return unless tag

      CacheBuster.bust_tag(tag)
    end
  end
end
