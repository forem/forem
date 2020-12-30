module Articles
  class RssReaderWorker
    include Sidekiq::Worker

    sidekiq_options queue: :medium_priority, retry: 10

    def perform
      # Temporary
      # @sre:mstruve This is temporary until we have an efficient way to handle this job
      # for our large DEV community. Smaller Forems should be able to handle it no problem
      return if SiteConfig.dev_to?

      if FeatureFlag.enabled?(:feeds_import)
        ::Feeds::ImportArticlesWorker.perform_async
      else
        # don't force fetch. Fetch "random" subset instead of all of them.
        ::RssReader.get_all_articles(force: false)
      end
    end
  end
end
