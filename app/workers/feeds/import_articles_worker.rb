module Feeds
  class ImportArticlesWorker
    include Sidekiq::Job
    include Sidekiq::Throttled::Job

    sidekiq_throttle(concurrency: { limit: 1 })

    sidekiq_options queue: :medium_priority, retry: 10, lock: :until_and_while_executing

    def perform(rss_feed_ids = [], earlier_than = nil)
      feeds_scope = RssFeed.active

      if rss_feed_ids.present?
        feeds_scope = feeds_scope.where(id: rss_feed_ids)
        earlier_than = nil
      else
        earlier_than ||= 4.hours.ago
      end

      if earlier_than.is_a?(Time)
        earlier_than = earlier_than.iso8601
      end

      feeds_scope.select(:id).find_in_batches do |batch|
        arg_lists = batch.map { |feed| [feed.id, earlier_than] }
        ForFeed.perform_bulk(arg_lists)
      end
    end

    class ForFeed
      include Sidekiq::Job
      include Sidekiq::Throttled::Job

      sidekiq_throttle(concurrency: { limit: 5 })

      def perform(rss_feed_ids, earlier_than)
        feeds_scope = RssFeed.where(id: rss_feed_ids)
        ::Feeds::Import.call(feeds_scope: feeds_scope, earlier_than: earlier_than)
      end
    end
  end
end
