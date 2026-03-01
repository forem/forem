module Feeds
  class Import
    def self.call(feeds_scope: RssFeed.active, earlier_than: nil)
      new(feeds_scope: feeds_scope, earlier_than: earlier_than).call
    end

    def initialize(feeds_scope: RssFeed.active, earlier_than: nil)
      @earlier_than = earlier_than
      @feeds = filter_feeds_from(feeds_scope: feeds_scope, earlier_than: earlier_than)
      @feeds_batch_size = 50
      @num_fetchers = 8
      @num_parsers = 4
    end

    def call
      total_articles_count = 0

      feeds.in_batches(of: feeds_batch_size) do |batch_of_feeds|
        feeds_per_feed_id = fetch_feeds(batch_of_feeds)
        feedjira_objects = parse_feeds(feeds_per_feed_id)

        articles = feedjira_objects.flat_map do |feed_id, parsed_feed|
          feed = batch_of_feeds.detect { |f| f.id == feed_id }
          create_articles_from_feed(feed, parsed_feed)
        end

        total_articles_count += articles.length
        batch_of_feeds.update_all(last_fetched_at: Time.current)
      end

      total_articles_count
    end

    private

    attr_reader :earlier_than, :feeds_batch_size, :num_fetchers, :num_parsers, :feeds

    def filter_feeds_from(feeds_scope:, earlier_than:)
      return feeds_scope unless earlier_than

      feeds_scope.where(last_fetched_at: nil).or(feeds_scope.where(last_fetched_at: ..earlier_than))
    end

    def fetch_feeds(batch_of_feeds)
      data = batch_of_feeds.pluck(:id, :url)

      result = Parallel.map(data, in_threads: num_fetchers) do |feed_id, url|
        cleaned_url = url.to_s.strip
        next if cleaned_url.blank?

        response = HTTParty.get(cleaned_url,
                                timeout: 10,
                                headers: { "User-Agent" => "Forem Feeds Importer" })

        [feed_id, response.body]
      rescue StandardError => e
        report_error(e, feeds_import_info: { feed_id: feed_id, url: url, error: "Feeds::Import::FetchFeedError" })
        next
      end

      result.compact.to_h
    end

    def parse_feeds(feeds_per_feed_id)
      result = Parallel.map(feeds_per_feed_id, in_threads: num_parsers) do |feed_id, feed_xml|
        parsed_feed = Feedjira.parse(feed_xml)
        [feed_id, parsed_feed]
      rescue StandardError => e
        report_error(e, feeds_import_info: { feed_id: feed_id, error: "Feeds::Import::ParseFeedError" })
        next
      end

      result.compact.to_h
    end

    def create_articles_from_feed(feed, parsed_feed)
      articles = []
      
      import_job = feed.rss_feed_imports.create!(status: :running)
      articles_found = parsed_feed.entries&.length || 0
      import_job.update(articles_found: articles_found)

      parsed_feed.entries.reverse_each do |item|
        feed_source_url = item.url.strip.split("?source=")[0]
        
        author = feed.fallback_user || feed.user
        organization = feed.fallback_organization

        if Feeds::CheckItemMediumReply.call(item) || Feeds::CheckItemPreviouslyImported.call(item, author)
          import_job.rss_feed_imported_articles.create!(source_url: feed_source_url, title: item.title, status: :skipped)
          next
        end

        article = Article.create!(
          feed_source_url: feed_source_url,
          user_id: author.id,
          published_from_feed: true,
          show_comments: true,
          body_markdown: Feeds::AssembleArticleMarkdown.call(item, author, feed, feed_source_url),
          organization_id: organization&.id,
        )

        subscribe_author_to_comments(author, article)
        articles.append(article)
        import_job.rss_feed_imported_articles.create!(source_url: feed_source_url, title: item.title, status: :imported, article_id: article.id)
      rescue StandardError => e
        import_job.rss_feed_imported_articles.create!(source_url: feed_source_url, title: item.title, status: :failed, error_message: e.message)
        report_error(e, feeds_import_info: { feed_url: feed.url, error: "Feeds::Import::CreateArticleError:#{item.url}" })
        next
      end

      import_job.update(status: :completed, articles_imported: articles.length)

      if articles.length.positive?
        Slack::WorkflowWebhookWorker.perform_async("Imported #{articles.length} articles from feed #{feed.url}")
      end

      articles
    rescue StandardError => e
      import_job&.update(status: :failed, error_message: e.message)
      articles
    end

    def report_error(error, metadata)
      Rails.logger.error("feeds::import::error::#{error.class}::#{metadata.merge(error_message: error.message)}")
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
