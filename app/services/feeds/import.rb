module Feeds
  class Import
    def self.call(users: nil, earlier_than: nil)
      new(users: users, earlier_than: earlier_than).call
    end

    def initialize(users: nil, earlier_than: nil)
      # using nil here to avoid an unnecessary table count to check presence
      @users = users || User.with_feed
      @earlier_than = earlier_than

      # NOTE: should these be configurable? Currently they are the result of empiric
      # tests trying to find a balance between memory occupation and speed
      @users_batch_size = 50
      @num_fetchers = 8
      @num_parsers = 4
    end

    def call
      total_articles_count = 0

      users.in_batches(of: users_batch_size) do |batch_of_users|
        feeds_per_user_id = fetch_feeds(batch_of_users)
        DatadogStatsClient.count("feeds::import::fetch_feeds.count", feeds_per_user_id.length)

        feedjira_objects = parse_feeds(feeds_per_user_id)
        DatadogStatsClient.count("feeds::import::parse_feeds.count", feedjira_objects.length)

        # NOTE: doing this sequentially to avoid locking problems with the DB
        # and unnecessary conflicts
        articles = feedjira_objects.flat_map do |user_id, feed|
          # TODO: replace `feed` with `feed.url` as `RssReader::Assembler`
          # only actually needs feed.url
          user = batch_of_users.detect { |u| u.id == user_id }

          DatadogStatsClient.time("feeds::import::create_articles_from_user_feed", tags: ["user_id:#{user_id}"]) do
            create_articles_from_user_feed(user, feed)
          end
        end

        total_articles_count += articles.length

        articles.each { |article| Slack::Messengers::ArticleFetchedFeed.call(article: article) }

        # we use `feed_fetched_at` to mark the last time a particular user's feed has been fetched, parsed and imported
        batch_of_users.update_all(feed_fetched_at: Time.current)
      end

      DatadogStatsClient.count("feeds::import::articles.count", total_articles_count)
      total_articles_count
    end

    private

    attr_reader :earlier_than, :users_batch_size, :num_fetchers, :num_parsers

    def users
      return @users unless earlier_than

      # Filtering users whose feed hasn't been processed in the last `earlier_than` time span.
      # New users + any user whose feed was processed earlier than the given time
      @users.where(feed_fetched_at: nil).or(@users.where(feed_fetched_at: ..earlier_than))
    end

    # TODO: put this in separate service object
    def fetch_feeds(batch_of_users)
      data = batch_of_users.pluck(:id, :feed_url)

      result = Parallel.map(data, in_threads: num_fetchers) do |user_id, url|
        cleaned_url = url.to_s.strip
        next if cleaned_url.blank?

        response = DatadogStatsClient.time("feeds::import::fetch_feed", tags: ["user_id:#{user_id}", "url:#{url}"]) do
          HTTParty.get(cleaned_url, timeout: 10)
        end

        [user_id, response.body]
      rescue StandardError => e
        # TODO: add better exception handling
        # For example, we should stop pulling feeds that return 404 and disable them?

        report_error(
          e,
          feeds_import_info: {
            user_id: user_id,
            url: url,
            error: "Feeds::Import::FetchFeedError"
          },
        )

        next
      end

      result.compact.to_h
    end

    # TODO: put this in separate service object
    def parse_feeds(feeds_per_user_id)
      result = Parallel.map(feeds_per_user_id, in_threads: num_parsers) do |user_id, feed_xml|
        parsed_feed = DatadogStatsClient.time("feeds::import::parse_feed", tags: ["user_id:#{user_id}"]) do
          Feedjira.parse(feed_xml)
        end

        [user_id, parsed_feed]
      rescue StandardError => e
        # TODO: add better exception handling (eg. rescueing Feedjira::NoParserAvailable separately)
        report_error(
          e,
          feeds_import_info: {
            user_id: user_id,
            error: "Feeds::Import::ParseFeedError"
          },
        )

        next
      end

      result.compact.to_h
    end

    # TODO: currently this is exactly as in RSSReader, but we might find
    # avenues for optimization, like:
    # 1. why are we sending N exists query to the DB, one per each item, can we fetch them all?
    # 2. should we queue a batch of workers to create articles, but then, following issues ensue:
    # => synchronization on write (table/row locking)
    # => what happens if 2 jobs are in the queue for the same article?
    # => what happens if they stay in the queue for long and the next iteration of the feeds importer starts?
    def create_articles_from_user_feed(user, feed)
      articles = []

      feed.entries.reverse_each do |item|
        next if Feeds::CheckItemMediumReply.call(item) || Feeds::CheckItemPreviouslyImported.call(item, user)

        feed_source_url = item.url.strip.split("?source=")[0]
        article = Article.create!(
          feed_source_url: feed_source_url,
          user_id: user.id,
          published_from_feed: true,
          show_comments: true,
          body_markdown: RssReader::Assembler.call(item, user, feed, feed_source_url),
          organization_id: nil,
        )

        articles.append(article)
      rescue StandardError => e
        # TODO: add better exception handling
        report_error(
          e,
          feeds_import_info: {
            username: user.username,
            feed_url: user.feed_url,
            item_count: item_count_error(feed),
            error: "Feeds::Import::CreateArticleError:#{item.url}"
          },
        )

        next
      end

      articles
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
  end
end
