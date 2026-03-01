module Feeds
  class ImportArticlesWorker
    include Sidekiq::Job
    include Sidekiq::Throttled::Job

    sidekiq_throttle(concurrency: { limit: 1 })

    sidekiq_options queue: :medium_priority, retry: 10, lock: :until_and_while_executing

    # NOTE: [@rhymes] we need to default earlier_than to `nil` because sidekiq-cron,
    # by using YAML to define jobs arguments does not support datetimes evaluated
    # at runtime
    def perform(user_ids = [], earlier_than = nil)
      rss_feeds_scope = RssFeed.fetchable

      if user_ids.present?
        rss_feeds_scope = rss_feeds_scope.where(user_id: user_ids)
        # we assume that forcing a single import should not take into account
        # the last time a feed was fetched at
        earlier_than = nil
      else
        # Only batch feeds for users who have been active recently
        recent_activity_since = 3.months.ago
        active_user_ids = User.where(
          "last_article_at >= ? OR last_presence_at >= ?",
          recent_activity_since, recent_activity_since
        ).select(:id)
        rss_feeds_scope = rss_feeds_scope.where(user_id: active_user_ids)

        earlier_than ||= 4.hours.ago
      end

      # For some reason `ActiveSupport::TimeWithZone#is_a?(Time)` evaluates to
      # `true` so this works with any sort of time object
      if earlier_than.is_a?(Time)
        earlier_than = earlier_than.iso8601
      end

      rss_feeds_scope.select(:id).find_in_batches do |batch|
        arg_lists = batch.map { |feed| [[feed.id], earlier_than] }

        ForFeed.perform_bulk(arg_lists)
      end
    end

    class ForFeed
      include Sidekiq::Job
      include Sidekiq::Throttled::Job

      sidekiq_throttle(concurrency: { limit: 5 })

      def perform(rss_feed_ids, earlier_than)
        rss_feeds_scope = RssFeed.fetchable.where(id: rss_feed_ids)

        ::Feeds::Import.call(rss_feeds_scope: rss_feeds_scope, earlier_than: earlier_than)
      end
    end

    # Kept for backward compatibility with in-flight Sidekiq jobs
    class ForUser
      include Sidekiq::Job
      include Sidekiq::Throttled::Job

      sidekiq_throttle(concurrency: { limit: 5 })

      def perform(user_ids, earlier_than)
        rss_feeds_scope = RssFeed.fetchable.where(user_id: user_ids)

        ::Feeds::Import.call(rss_feeds_scope: rss_feeds_scope, earlier_than: earlier_than)
      end
    end
  end
end
