module Feeds
  # Responsible for fetching RSS feeds for multiple feed sources.
  #
  # @see Feeds::Import.call
  class Import
    # Fetch the feeds for the given scope of feed sources.
    #
    # @param users_scope [ActiveRecord::Relation<User>] the initial scope for determining which
    #        users' feed sources we'll be fetching.
    #
    # @param earlier_than [NilClass, ActiveSupport::TimeWithZone] when given, use this to further
    #        filter which feed sources to fetch (based on last_fetched_at).
    #
    # @return [Integer] count of total articles fetched.
    def self.call(users_scope: User, earlier_than: nil)
      new(users_scope: users_scope, earlier_than: earlier_than).call
    end

    def initialize(users_scope: User, earlier_than: nil)
      @earlier_than = earlier_than
      @feed_sources = filter_feed_sources(users_scope: users_scope, earlier_than: earlier_than)

      # NOTE: should these be configurable? Currently they are the result of empiric
      # tests trying to find a balance between memory occupation and speed
      @sources_batch_size = 50
      @num_fetchers = 8
      @num_parsers = 4
    end

    def call
      total_articles_count = 0

      feed_sources.in_batches(of: sources_batch_size) do |batch_of_sources|
        sources = batch_of_sources.includes(:user, :organization, :author).to_a
        sources_by_id = sources.index_by(&:id)

        fetch_results = fetch_feeds(sources, sources_by_id)
        feeds_per_source_id = fetch_results[:feeds]

        feedjira_objects, parse_failures = parse_feeds(feeds_per_source_id)

        # Record fetch failures
        record_fetch_failures(fetch_results[:failures], sources_by_id)

        # Record parse failures
        record_parse_failures(parse_failures, sources_by_id)

        # NOTE: doing this sequentially to avoid locking problems with the DB
        articles = feedjira_objects.flat_map do |source_id, feed|
          source = sources_by_id[source_id]
          create_articles_from_feed_source(source, feed)
        end

        total_articles_count += articles.length

        # Update last_fetched_at on each source and the user's feed_fetched_at for backward compat
        now = Time.current
        batch_of_sources.update_all(last_fetched_at: now)
        user_ids = sources.map(&:user_id).uniq
        User.where(id: user_ids).update_all(feed_fetched_at: now)
      end

      total_articles_count
    end

    private

    attr_reader :earlier_than, :sources_batch_size, :num_fetchers, :num_parsers, :feed_sources

    def filter_feed_sources(users_scope:, earlier_than:)
      authorized_user_ids = ArticlePolicy
        .scope_users_authorized_to_action(users_scope: users_scope, action: :create)
        .select(:id)

      recent_activity_since = 3.months.ago
      active_user_ids = User
        .where(id: authorized_user_ids)
        .where("last_article_at >= ? OR last_presence_at >= ?",
               recent_activity_since, recent_activity_since)
        .select(:id)

      sources = Feeds::Source.active.where(user_id: active_user_ids)

      return sources unless earlier_than

      sources.where(last_fetched_at: nil).or(sources.where(last_fetched_at: ..earlier_than))
    end

    def fetch_feeds(sources, sources_by_id)
      data = sources.map { |s| [s.id, s.feed_url] }
      failures = []

      result = Parallel.map(data, in_threads: num_fetchers) do |source_id, url|
        cleaned_url = url.to_s.strip
        next if cleaned_url.blank?

        response = HTTParty.get(cleaned_url,
                                timeout: 10,
                                headers: { "User-Agent" => "Forem Feeds Importer" })

        [source_id, response.body]
      rescue StandardError => e
        source = sources_by_id[source_id]
        report_error(
          e,
          feeds_import_info: {
            source_id: source_id,
            user_id: source&.user_id,
            url: url,
            error: "Feeds::Import::FetchFeedError"
          },
        )

        failures << { source_id: source_id, feed_url: url, error: sanitize_error(e.message) }
        next
      end

      { feeds: result.compact.to_h, failures: failures }
    end

    def parse_feeds(feeds_per_source_id)
      failures = []

      result = Parallel.map(feeds_per_source_id, in_threads: num_parsers) do |source_id, feed_xml|
        parsed_feed = Feedjira.parse(feed_xml)

        [source_id, parsed_feed]
      rescue StandardError => e
        report_error(
          e,
          feeds_import_info: {
            source_id: source_id,
            error: "Feeds::Import::ParseFeedError"
          },
        )

        failures << { source_id: source_id, error: sanitize_error(e.message) }
        next
      end

      [result.compact.to_h, failures]
    end

    def create_articles_from_feed_source(feed_source, feed)
      start_time = Time.current
      articles = []
      user = feed_source.user
      import_log = Feeds::ImportLog.create!(
        user: user,
        feed_source: feed_source,
        status: :importing,
        feed_url: feed_source.feed_url,
        items_in_feed: feed.entries.size,
      )

      items_imported = 0
      items_skipped = 0
      items_failed = 0

      feed.entries.reverse_each do |item|
        if Feeds::CheckItemMediumReply.call(item)
          items_skipped += 1
          record_import_item(import_log, item, :skipped_medium_reply)
          next
        end

        author = Feeds::ResolveAuthor.call(item, feed_source)

        if Feeds::CheckItemPreviouslyImported.call(item, author)
          items_skipped += 1
          record_import_item(import_log, item, :skipped_duplicate)
          next
        end

        feed_source_url = item.url.strip.split("?source=")[0]
        article = Article.create!(
          feed_source_url: feed_source_url,
          user_id: author.id,
          published_from_feed: true,
          show_comments: true,
          body_markdown: Feeds::AssembleArticleMarkdown.call(item, author, feed, feed_source_url,
                                                             feed_source: feed_source),
          organization_id: feed_source.organization_id,
        )

        subscribe_author_to_comments(author, article)
        articles.append(article)
        items_imported += 1
        record_import_item(import_log, item, :imported, article: article)
      rescue StandardError => e
        report_error(
          e,
          feeds_import_info: {
            username: user.username,
            feed_url: feed_source.feed_url,
            item_count: item_count_error(feed),
            error: "Feeds::Import::CreateArticleError:#{item.url}"
          },
        )

        items_failed += 1
        record_import_item(import_log, item, :failed, error_message: sanitize_error(e.message))
        next
      end

      duration = Time.current - start_time
      import_log.update!(
        status: :completed,
        items_imported: items_imported,
        items_skipped: items_skipped,
        items_failed: items_failed,
        duration_seconds: duration,
      )
      feed_source.update_health!(success: true)

      if articles.length.positive?
        Slack::WorkflowWebhookWorker.perform_async("Imported #{articles.length} articles for #{user.username}")
      end

      articles
    end

    def record_import_item(import_log, item, status, article: nil, error_message: nil)
      Feeds::ImportItem.create!(
        import_log: import_log,
        feed_item_url: item.url.to_s.strip.truncate(500),
        feed_item_title: item.title.to_s.strip.truncate(255),
        status: status,
        article: article,
        error_message: error_message,
      )
    rescue StandardError => e
      Rails.logger.error("feeds::import::tracking_error::#{e.class}::#{e.message}")
    end

    def record_fetch_failures(failures, sources_by_id)
      failures.each do |failure|
        source = sources_by_id[failure[:source_id]]
        next unless source

        Feeds::ImportLog.create!(
          user: source.user,
          feed_source: source,
          status: :failed,
          feed_url: failure[:feed_url],
          error_message: failure[:error],
        )
        source.update_health!(success: false)
      rescue StandardError => e
        Rails.logger.error("feeds::import::tracking_error::#{e.class}::#{e.message}")
      end
    end

    def record_parse_failures(failures, sources_by_id)
      failures.each do |failure|
        source = sources_by_id[failure[:source_id]]
        next unless source

        Feeds::ImportLog.create!(
          user: source.user,
          feed_source: source,
          status: :failed,
          feed_url: source.feed_url,
          error_message: failure[:error],
        )
        source.update_health!(success: false)
      rescue StandardError => e
        Rails.logger.error("feeds::import::tracking_error::#{e.class}::#{e.message}")
      end
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

    def sanitize_error(message)
      message.to_s.gsub(%r{/[\w/.-]+\.rb:\d+}, "[path]").truncate(500)
    end
  end
end
