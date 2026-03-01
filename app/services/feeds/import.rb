module Feeds
  # Responsible for fetching RSS feeds for multiple RssFeed records.
  #
  # @see Feeds::Import.call
  class Import
    # Fetch the feeds for the given RssFeed scope (with some filtering based on internal business logic).
    #
    # @param rss_feeds_scope [ActiveRecord::Relation<RssFeed>] the initial scope for determining which
    #        feeds we'll be fetching.
    #
    # @param earlier_than [NilClass, ActiveSupport::TimeWithZone] when given, use this to further
    #        filter which feeds we'll fetch. We won't fetch any feed whose last fetch time was
    #        after our earlier_than parameter.
    #
    # @return [Integer] count of total articles fetched.
    def self.call(rss_feeds_scope: RssFeed.fetchable, earlier_than: nil)
      new(rss_feeds_scope: rss_feeds_scope, earlier_than: earlier_than).call
    end

    def initialize(rss_feeds_scope: RssFeed.fetchable, earlier_than: nil)
      @earlier_than = earlier_than
      @rss_feeds = filter_feeds(rss_feeds_scope: rss_feeds_scope, earlier_than: earlier_than)

      # NOTE: should these be configurable? Currently they are the result of empiric
      # tests trying to find a balance between memory occupation and speed
      @feeds_batch_size = 50
      @num_fetchers = 8
      @num_parsers = 4
    end

    def call
      total_articles_count = 0

      rss_feeds.in_batches(of: feeds_batch_size) do |batch_of_feeds|
        feeds_with_users = batch_of_feeds.includes(:user)

        raw_feeds = fetch_feeds(feeds_with_users)

        feedjira_objects = parse_feeds(raw_feeds)

        # NOTE: doing this sequentially to avoid locking problems with the DB
        # and unnecessary conflicts
        articles = feedjira_objects.flat_map do |rss_feed_id, parsed_feed|
          rss_feed = feeds_with_users.detect { |f| f.id == rss_feed_id }

          create_articles_from_feed(rss_feed, parsed_feed)
        end

        total_articles_count += articles.length

        batch_of_feeds.update_all(last_fetched_at: Time.current)
      end

      total_articles_count
    end

    private

    attr_reader :earlier_than, :feeds_batch_size, :num_fetchers, :num_parsers, :rss_feeds

    # @return [ActiveRecord::Relation<RssFeed>]
    def filter_feeds(rss_feeds_scope:, earlier_than:)
      # Only include feeds whose owners are authorized to create articles
      authorized_user_ids = ArticlePolicy.scope_users_authorized_to_action(
        users_scope: User, action: :create,
      ).select(:id)
      rss_feeds_scope = rss_feeds_scope.where(user_id: authorized_user_ids)

      # Only include feeds for recently active users
      recent_activity_since = 3.months.ago
      active_user_ids = User.where(
        "last_article_at >= ? OR last_presence_at >= ?",
        recent_activity_since, recent_activity_since
      ).select(:id)
      rss_feeds_scope = rss_feeds_scope.where(user_id: active_user_ids)

      return rss_feeds_scope unless earlier_than

      # Filtering feeds that haven't been processed in the last `earlier_than` time span.
      rss_feeds_scope.where(last_fetched_at: nil)
        .or(rss_feeds_scope.where(last_fetched_at: ..earlier_than))
    end

    def fetch_feeds(batch_of_feeds)
      data = batch_of_feeds.pluck(:id, :feed_url)

      result = Parallel.map(data, in_threads: num_fetchers) do |rss_feed_id, url|
        cleaned_url = url.to_s.strip
        next if cleaned_url.blank?

        response = HTTParty.get(cleaned_url,
                                timeout: 10,
                                headers: { "User-Agent" => "Forem Feeds Importer" })

        [rss_feed_id, response.body]
      rescue StandardError => e
        report_error(
          e,
          feeds_import_info: {
            rss_feed_id: rss_feed_id,
            url: url,
            error: "Feeds::Import::FetchFeedError"
          },
        )

        RssFeed.where(id: rss_feed_id).update_all(status: :error, last_error_message: e.message.truncate(255))

        next
      end

      result.compact.to_h
    end

    def parse_feeds(feeds_per_rss_feed_id)
      result = Parallel.map(feeds_per_rss_feed_id, in_threads: num_parsers) do |rss_feed_id, feed_xml|
        parsed_feed = Feedjira.parse(feed_xml)

        [rss_feed_id, parsed_feed]
      rescue StandardError => e
        report_error(
          e,
          feeds_import_info: {
            rss_feed_id: rss_feed_id,
            error: "Feeds::Import::ParseFeedError"
          },
        )

        RssFeed.where(id: rss_feed_id).update_all(status: :error, last_error_message: e.message.truncate(255))

        next
      end

      result.compact.to_h
    end

    def create_articles_from_feed(rss_feed, parsed_feed)
      user = rss_feed.fallback_author || rss_feed.user
      articles = []

      parsed_feed.entries.reverse_each do |item|
        article = import_feed_entry(rss_feed, user, item, parsed_feed)
        articles << article if article
      end

      if articles.length.positive?
        Slack::WorkflowWebhookWorker.perform_async("Imported #{articles.length} articles for #{user.username}")
      end

      articles
    end

    def import_feed_entry(rss_feed, user, item, parsed_feed)
      return if Feeds::CheckItemMediumReply.call(item) || Feeds::CheckItemPreviouslyImported.call(item, user)

      feed_source_url = item.url.strip.split("?source=")[0]
      feed_item = find_or_init_feed_item(rss_feed, item, feed_source_url)

      if feed_item.imported? && feed_item.article_id.present?
        feed_item.save! if feed_item.changed?
        return
      end

      article = Article.create!(
        feed_source_url: feed_source_url,
        user_id: user.id,
        published_from_feed: true,
        show_comments: true,
        body_markdown: Feeds::AssembleArticleMarkdown.call(item, user, rss_feed, feed_source_url),
        organization_id: rss_feed.fallback_organization_id,
        rss_feed_id: rss_feed.id,
      )

      feed_item.update!(status: :imported, article: article, processed_at: Time.current)
      subscribe_author_to_comments(user, article)
      article
    rescue StandardError => e
      feed_item&.update(status: :error, error_message: e.message.truncate(255), processed_at: Time.current)
      report_error(
        e,
        feeds_import_info: {
          rss_feed_id: rss_feed.id,
          username: user.username,
          feed_url: rss_feed.feed_url,
          item_count: item_count_error(parsed_feed),
          error: "Feeds::Import::CreateArticleError:#{item.url}"
        },
      )
      nil
    end

    def find_or_init_feed_item(rss_feed, item, feed_source_url)
      feed_item = rss_feed.rss_feed_items.find_or_initialize_by(item_url: feed_source_url)
      feed_item.title = item.title&.strip&.truncate(512)
      feed_item.detected_at ||= Time.current
      feed_item
    end

    def report_error(error, metadata)
      Rails.logger.error(
        "feeds::import::error::#{error.class}::#{metadata.merge(error_message: error.message)}",
      )
    end

    def item_count_error(feed)
      return "NIL FEED, INVALID URL" unless feed

      feed.entries ? feed.entries.length : "no count"
    end

    def subscribe_author_to_comments(user, article)
      NotificationSubscription.create!(
        user: user,
        notifiable_id: article.id,
        notifiable_type: "Article",
        config: "all_comments",
      )
    end
  end
end
