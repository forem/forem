module Feeds
  # Responsible for fetching RSS feeds for multiple feed sources.
  #
  # @see Feeds::Import.call
  class Import
    MAX_XML_SIZE = 2.megabytes
    MAX_XML_ENTRIES = 100
    MAX_ENTRIES_PER_FEED = 25
    FEED_USER_AGENT = "Forem/1.0 (+https://forem.com; RSS Feed Fetcher)".freeze
    MAX_FETCH_RETRIES = 2

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
        feeds_per_source_id.clear

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

    def map_in_threads(collection, max_threads, &block)
      return [] if collection.empty?
      return collection.map(&block) if collection.size <= 1 || max_threads <= 1

      Parallel.map(collection, in_threads: [collection.size, max_threads].min, &block)
    end

    def fetch_feeds(sources, sources_by_id)
      data = sources.map { |s| [s.id, s.feed_url] }
      failures = []
      mutex = Mutex.new

      result = map_in_threads(data, num_fetchers) do |source_id, url|
        cleaned_url = url.to_s.strip
        next if cleaned_url.blank?

        body = fetch_with_retry(cleaned_url)

        [source_id, body]
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

        sanitized = sanitize_error(e.message)
        mutex.synchronize do
          failures << { source_id: source_id, feed_url: url, error: sanitized }
        end
        next
      end

      { feeds: result.compact.to_h, failures: failures }
    end

    def parse_feeds(feeds_per_source_id)
      failures = []
      mutex = Mutex.new

      result = map_in_threads(feeds_per_source_id, num_parsers) do |source_id, feed_xml|
        xml_for_scan = normalize_xml_encoding(feed_xml)
        bounded_xml = ForemNative.truncate_feed_xml_items(xml_for_scan, MAX_XML_ENTRIES) || feed_xml
        parsed_feed = Feedjira.parse(bounded_xml)

        [source_id, parsed_feed]
      rescue StandardError => e
        report_error(
          e,
          feeds_import_info: {
            source_id: source_id,
            error: "Feeds::Import::ParseFeedError"
          },
        )

        sanitized = sanitize_error(e.message)
        mutex.synchronize do
          failures << { source_id: source_id, error: sanitized }
        end
        next
      end

      [result.compact.to_h, failures]
    end

    def create_articles_from_feed_source(feed_source, feed)
      start_time = Time.current
      articles = []
      user = feed_source.user
      entries = select_recent_entries(feed.entries)
      import_log = Feeds::ImportLog.create!(
        user: user,
        feed_source: feed_source,
        status: :importing,
        feed_url: feed_source.feed_url,
        items_in_feed: entries.size,
      )

      items_imported = 0
      items_skipped = 0
      items_failed = 0

      # Pre-load URLs already tracked as skipped for this source to avoid re-recording them
      previously_skipped_urls = Feeds::ImportItem
        .joins(:import_log)
        .where(feed_import_logs: { feed_source_id: feed_source.id })
        .where(status: %i[skipped_duplicate skipped_medium_reply])
        .pluck(:feed_item_url)
        .to_set

      authors_cache = {}
      existing_identifiers_by_author_id = {}

      entries.reverse_each do |item|
        outcome = process_feed_entry(
          item, feed_source, feed, entries, import_log,
          previously_skipped_urls, authors_cache, existing_identifiers_by_author_id
        )
        case outcome
        when :skipped
          items_skipped += 1
        when Article
          articles.append(outcome)
          items_imported += 1
        end
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

    def process_feed_entry(item, feed_source, feed, entries, import_log,
                           previously_skipped_urls, authors_cache, existing_identifiers_by_author_id)
      if Feeds::CheckItemMediumReply.call(item)
        item_url = item.url.to_s.strip.truncate(500)
        record_import_item(import_log, item, :skipped_medium_reply) unless previously_skipped_urls.include?(item_url)
        return :skipped
      end

      author_key = item.try(:author).to_s.strip
      author = authors_cache[author_key] ||= Feeds::ResolveAuthor.call(item, feed_source)

      if item_previously_imported?(item, author, entries, existing_identifiers_by_author_id)
        item_url = item.url.to_s.strip.truncate(500)
        record_import_item(import_log, item, :skipped_duplicate) unless previously_skipped_urls.include?(item_url)
        return :skipped
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

      record_author_imported_identifier(author, item, feed_source_url, existing_identifiers_by_author_id)
      subscribe_author_to_comments(author, article)
      record_import_item(import_log, item, :imported, article: article)
      article
    end

    def item_previously_imported?(item, author, entries, cache)
      return false if item.nil? || item.url.blank? || item.title.blank?

      urls_set, titles_set = cache[author.id] ||= preload_existing_identifiers_for_author(author, entries)
      cleaned_title = item.title.to_s.strip.gsub('"', '\"')
      normalized_url = item.url.to_s.strip.split("?source=")[0]

      urls_set.include?(normalized_url) || titles_set.include?(cleaned_title)
    end

    def record_author_imported_identifier(author, item, feed_source_url, cache)
      pair = cache[author.id]
      return unless pair

      urls_set, titles_set = pair
      urls_set << feed_source_url if feed_source_url.present?
      cleaned_title = item.title.to_s.strip.gsub('"', '\"')
      titles_set << cleaned_title if cleaned_title.present?
    end

    def preload_existing_identifiers_for_author(author, entries)
      candidate_urls, candidate_titles = extract_candidate_identifiers(entries)
      return [Set.new, Set.new] if candidate_urls.empty? && candidate_titles.empty?

      query = existing_articles_query(author.articles, candidate_urls, candidate_titles)
      build_identifier_sets(query)
    end

    def extract_candidate_identifiers(entries)
      valid_entries = entries.reject { |entry| entry.nil? || entry.url.blank? || entry.title.blank? }
      candidate_urls = valid_entries.map { |entry| entry.url.to_s.strip.split("?source=")[0] }.compact_blank.uniq
      candidate_titles = valid_entries.map { |entry| entry.title.to_s.strip.gsub('"', '\"') }.compact_blank.uniq
      [candidate_urls, candidate_titles]
    end

    def existing_articles_query(scope, candidate_urls, candidate_titles)
      if candidate_urls.any? && candidate_titles.any?
        scope.where(feed_source_url: candidate_urls).or(scope.where(title: candidate_titles))
      elsif candidate_urls.any?
        scope.where(feed_source_url: candidate_urls)
      else
        scope.where(title: candidate_titles)
      end
    end

    def build_identifier_sets(query)
      urls_set = Set.new
      titles_set = Set.new
      query.pluck(:feed_source_url, :title).each do |url, title|
        urls_set << url if url.present?
        titles_set << title if title.present?
      end
      [urls_set, titles_set]
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
      str = message.to_s
      ForemNative.sanitize_feed_error(str) || str.gsub(%r{/[\w/.-]+\.rb:\d+}, "[path]").truncate(500)
    end

    def fetch_with_retry(url, retries: 0)
      body = +""
      streamed = false
      response = HTTParty.get(
        url,
        timeout: 20,
        stream_body: true,
        headers: { "User-Agent" => FEED_USER_AGENT },
      ) do |fragment|
        streamed = true
        next if fragment.respond_to?(:code) && (300..399).cover?(fragment.code)

        body << fragment.to_s
        if body.bytesize > MAX_XML_SIZE
          raise StandardError, "Feed XML exceeds maximum size of #{MAX_XML_SIZE} bytes (#{body.bytesize} bytes)"
        end
      end

      unless streamed
        body = response.respond_to?(:body) ? response.body.to_s : response.to_s
        if body.bytesize > MAX_XML_SIZE
          raise StandardError, "Feed XML exceeds maximum size of #{MAX_XML_SIZE} bytes (#{body.bytesize} bytes)"
        end
      end

      normalize_xml_encoding(body)
    rescue Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNRESET => e
      raise e if retries >= MAX_FETCH_RETRIES

      sleep(2**retries)
      fetch_with_retry(url, retries: retries + 1)
    end

    def normalize_xml_encoding(body)
      return body unless body.is_a?(String) && body.encoding == Encoding::BINARY

      prolog = body.byteslice(0, 256)
      declared = prolog[/\A\s*<\?xml[^>]*encoding\s*=\s*["']([^"']+)["']/i, 1]
      return body if declared && !declared.casecmp?("utf-8") && !declared.casecmp?("us-ascii")

      utf8_body = body.dup.force_encoding(Encoding::UTF_8)
      utf8_body.valid_encoding? ? utf8_body : body
    end

    def select_recent_entries(raw_entries)
      entries = raw_entries || []
      return entries if entries.size <= MAX_ENTRIES_PER_FEED

      if entries.first.respond_to?(:published) && entries.last.respond_to?(:published) &&
          entries.first.published && entries.last.published &&
          entries.first.published < entries.last.published
        entries = entries.each_with_index.sort_by do |entry, idx|
          pub = entry.respond_to?(:published) ? entry.published : nil
          [pub ? 0 : 1, pub ? -pub.to_f : 0.0, idx]
        end.map(&:first)
      end

      entries.first(MAX_ENTRIES_PER_FEED)
    end
  end
end
