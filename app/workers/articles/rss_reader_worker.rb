module Articles
  class RssReaderWorker
    include Sidekiq::Worker

    sidekiq_options queue: :medium_priority, retry: 10

    def perform
      if FeatureFlag.enabled?(:feeds_import)
        ::Feeds::ImportArticlesWorker.perform_async
      else
        # don't force fetch. Fetch "random" subset instead of all of them.
        ::RssReader.get_all_articles(force: false)
      end
    end
  end
end
